import XCTest
@testable import EduAccess

/// Answers every request with an empty 200 and keeps what it was sent.
final class RecordingProtocol: URLProtocol {
    nonisolated(unsafe) static var requests: [URLRequest] = []

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requests.append(request)
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data())
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

/// The JSON here is copied from real responses of the Django backend.
final class LiveAPIClientTests: XCTestCase {
    func testDecodesProfessor() throws {
        let json = #"[{"id":3,"username":"prof1","display_name":"Ashish Gupta","availability_status":"Free","status_note":null,"cabin_label":"AB2 FB3 : 106","directions_url":"/go/AB2/FB3/106/","is_mine":false,"open_today":[]}]"#

        let professors = try LiveAPIClient.decoder.decode([Professor].self, from: Data(json.utf8))

        XCTAssertEqual(professors, [.sample(isMine: false)])
    }

    func testDecodesProfessorWithNoteAndWalkInWindow() throws {
        let json = #"{"id":3,"username":"prof1","display_name":"Ashish Gupta","availability_status":"Busy","status_note":{"pick":"Lunch","text":"","until":null},"cabin_label":"AB2 FB3 : 106","directions_url":"/go/AB2/FB3/106/","is_mine":true,"open_today":[{"start":"2026-11-07T10:00:00+05:30","end":"2026-11-07T10:30:00+05:30"}]}"#

        let professor = try LiveAPIClient.decoder.decode(Professor.self, from: Data(json.utf8))

        XCTAssertTrue(professor.isMine)
        XCTAssertEqual(professor.directionsUrl, "/go/AB2/FB3/106/")
        XCTAssertEqual(professor.noteSummary, "Lunch")
        XCTAssertEqual(professor.openToday.count, 1)
        XCTAssertNotNil(professor.openTodaySummary)
    }

    func testBookingBodyUsesBackendFieldNames() throws {
        let request = BookingRequest(professor: 3, appointmentTime: Date(timeIntervalSince1970: 0), slots: 2, topic: .marks, details: "Chapter 3")

        let data = try LiveAPIClient.encoder.encode(request)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["appointment_time"] as? String, "1970-01-01T00:00:00Z")
        XCTAssertEqual(json["slots"] as? Int, 2)
        XCTAssertEqual(json["topic"] as? String, "Marks")
        XCTAssertEqual(json["details"] as? String, "Chapter 3")
    }

    func testDecodesAppointmentWithTimeZoneOffset() throws {
        let json = #"{"id":1,"student":1,"student_name":"Riya Sharma","professor":3,"professor_name":"Ashish Gupta","appointment_time":"2026-11-07T01:30:00+05:30","slots":1,"end_time":"2026-11-07T01:45:00+05:30","status":"Pending","topic":"Doubt","details":""}"#

        let appointment = try LiveAPIClient.decoder.decode(Appointment.self, from: Data(json.utf8))

        XCTAssertEqual(appointment.professorName, "Ashish Gupta")
        XCTAssertEqual(appointment.status, .pending)
        XCTAssertEqual(appointment.topic, .doubt)
        XCTAssertEqual(appointment.appointmentTime, ISO8601DateFormatter().date(from: "2026-11-06T20:00:00Z"))
        XCTAssertEqual(appointment.endTime, ISO8601DateFormatter().date(from: "2026-11-06T20:15:00Z"))
    }

    func testDecodesDatesWithFractionalSeconds() throws {
        let json = #"{"pick":"In class","text":"","until":"2026-11-07T01:30:00.250000+05:30"}"#

        let note = try LiveAPIClient.decoder.decode(StatusNote.self, from: Data(json.utf8))

        XCTAssertEqual(note.until?.timeIntervalSince1970 ?? 0, ISO8601DateFormatter().date(from: "2026-11-06T20:00:00Z")!.timeIntervalSince1970 + 0.25, accuracy: 0.001)
    }

    func testDecodesNotificationWithFractionalSeconds() throws {
        let json = #"[{"id":1,"message":"New appointment request","sent_at":"2026-11-06T03:27:10.123456+05:30"}]"#

        let notifications = try LiveAPIClient.decoder.decode([AppNotification].self, from: Data(json.utf8))

        XCTAssertEqual(notifications.first?.message, "New appointment request")
    }

    func testDecodesMe() throws {
        let json = #"{"id":3,"username":"prof1","display_name":"Ashish Gupta","role":"professor","availability_status":"Busy","status_note":{"pick":"In class","text":"Back soon","until":null},"cabin_label":"AB2 FB3 : 106"}"#

        let me = try LiveAPIClient.decoder.decode(Me.self, from: Data(json.utf8))

        XCTAssertEqual(me.availabilityStatus, .busy)
        XCTAssertEqual(me.statusNote, StatusNote(pick: "In class", text: "Back soon", until: nil))
    }

    func testAvailabilityUpdateSendsNullToClearTheBackTime() throws {
        let update = AvailabilityUpdate(availabilityStatus: .free, statusPick: "", statusText: "", statusUntil: nil)

        let data = try LiveAPIClient.encoder.encode(update)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["availability_status"] as? String, "Free")
        XCTAssertEqual(json["status_pick"] as? String, "")
        XCTAssertTrue(json["status_until"] is NSNull)
    }

    func testBaseURLAcceptsATrailingSlashAndRejectsBadAddresses() {
        XCTAssertEqual(LiveAPIClient.baseURL(from: "https://example.test/")?.absoluteString, "https://example.test")
        XCTAssertEqual(LiveAPIClient.baseURL(from: "https://example.test:8443")?.absoluteString, "https://example.test:8443")
        XCTAssertNil(LiveAPIClient.baseURL(from: ""))
        XCTAssertNil(LiveAPIClient.baseURL(from: "$(API_BASE_URL)"))
        XCTAssertNil(LiveAPIClient.baseURL(from: "ftp://example.test"))
    }

    func testWritesSendCSRFTokenAndRefererForHTTPS() async throws {
        let client = stubbedClient()

        try await client.logout()

        let request = try XCTUnwrap(RecordingProtocol.requests.last)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-CSRFToken"), "token123")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Referer"), "https://example.test/")
    }

    func testLoginFormSendsRefererForHTTPS() async throws {
        let client = stubbedClient()

        try await client.login(username: "student1", password: "secret", role: .student)

        let request = try XCTUnwrap(RecordingProtocol.requests.last)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Referer"), "https://example.test/")
    }

    private func stubbedClient() -> LiveAPIClient {
        RecordingProtocol.requests = []
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RecordingProtocol.self]
        configuration.httpCookieStorage?.setCookie(HTTPCookie(properties: [
            .domain: "example.test", .path: "/", .name: "csrftoken", .value: "token123", .secure: "TRUE",
        ])!)
        return LiveAPIClient(baseURL: URL(string: "https://example.test")!, session: URLSession(configuration: configuration))
    }

    func testReadsDetailError() {
        let body = Data(#"{"detail":"Type at least 2 characters to search."}"#.utf8)
        XCTAssertEqual(APIError.server(body: body), .server("Type at least 2 characters to search."))
    }

    func testReadsFieldError() {
        let body = Data(#"{"appointment_time":["Appointment time must be in the future."]}"#.utf8)
        XCTAssertEqual(APIError.server(body: body), .server("Appointment time must be in the future."))
    }

    func testNonJSONErrorFallsBackToGenericMessage() {
        XCTAssertEqual(APIError.server(body: Data("<html>".utf8)), .server("Something went wrong. Please try again."))
    }

    func testFormBodyEscapesReservedCharacters() {
        let body = LiveAPIClient.formBody(["password": "a+b&c=d e"])
        XCTAssertEqual(String(decoding: body, as: UTF8.self), "password=a%2Bb%26c%3Dd%20e")
    }

    func testURLsKeepExactlyOneTrailingSlash() {
        let client = LiveAPIClient(baseURL: URL(string: "https://example.test")!)
        XCTAssertEqual(client.url("login/").absoluteString, "https://example.test/login/")
        XCTAssertEqual(client.url("api/appointments/5/").absoluteString, "https://example.test/api/appointments/5/")
    }
}
