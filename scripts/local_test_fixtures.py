# Test data for a local backend, on top of seed_demo. Never run this against a deployed backend.
# Usage, from the backend checkout: python manage.py shell < path/to/local_test_fixtures.py
from api.management.commands.seed_demo import DEMO_PASSWORD
from api.models import AcademicBlock, CustomUser, FacultyBlock

ab1, _ = AcademicBlock.objects.get_or_create(number=1)
ab2, _ = AcademicBlock.objects.get_or_create(number=2)
FacultyBlock.objects.get_or_create(academic_block=ab1, number=2, defaults={'floor': 2})
FacultyBlock.objects.get_or_create(academic_block=ab2, number=3, defaults={'floor': 1})
FacultyBlock.objects.get_or_create(academic_block=ab2, number=4)

# Professors with no cabin, for the first-login gate. Running this again clears their cabins.
for username in ('nocabin1', 'nocabin2'):
    user, _ = CustomUser.objects.update_or_create(
        username=username,
        defaults={'role': 'professor', 'first_name': 'No', 'last_name': 'Cabin', 'email': '', 'college_id': '',
                  'academic_block': None, 'faculty_block': None, 'cabin': ''},
    )
    user.set_password(DEMO_PASSWORD)
    user.save()
