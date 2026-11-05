import XCTest
@testable import EduAccess

/// The JSON here is copied from real responses of the Django backend.
final class LiveAPIClientTests: XCTestCase {
    func testDecodesProfessor() throws {
        let json = #"[{"id":3,"username":"prof1","display_name":"Ashish Gupta","availability_status":"Free","status_note":null,"cabin_label":"AB2 FB3 : 106","directions_url":"/go/AB2/FB3/106/","is_mine":false,"open_today":[]}]"#

        let professors = try LiveAPIClient.decoder.decode([Professor].self, from: Data(json.utf8))

        XCTAssertEqual(professors, [Professor(id: 3, displayName: "Ashish Gupta", availabilityStatus: .free, cabinLabel: "AB2 FB3 : 106")])
    }

    func testDecodesAppointmentWithTimeZoneOffset() throws {
        let json = #"{"id":1,"student":1,"student_name":"Riya Sharma","professor":3,"professor_name":"Ashish Gupta","appointment_time":"2026-11-07T01:30:00+05:30","slots":1,"end_time":"2026-11-07T01:45:00+05:30","status":"Pending","topic":"Doubt","details":""}"#

        let appointment = try LiveAPIClient.decoder.decode(Appointment.self, from: Data(json.utf8))

        XCTAssertEqual(appointment.professorName, "Ashish Gupta")
        XCTAssertEqual(appointment.status, .pending)
        XCTAssertEqual(appointment.topic, .doubt)
        XCTAssertEqual(appointment.appointmentTime, ISO8601DateFormatter().date(from: "2026-11-06T20:00:00Z"))
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
        XCTAssertEqual(LiveAPIClient().url("login/").absoluteString, "http://127.0.0.1:8000/login/")
        XCTAssertEqual(LiveAPIClient().url("api/appointments/5/").absoluteString, "http://127.0.0.1:8000/api/appointments/5/")
    }
}
