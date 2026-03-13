import '../mappers/pet_mapper.dart';
import '../models/pet_ui_model.dart';

/// Handles data fetching for the Pets feature.
///
/// TODO: Replace [_mockPets] with a real HTTP GET to /api/pets once the
/// auth token and base URL are configured.
class PetsApiService {
  Future<List<PetUiModel>> fetchPets() async {
    // Simulate network latency while using mock data.
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockPets.map(PetMapper.fromJson).toList();
  }
}


// Mock data
// Replace this list when wiring the real endpoint.
const List<Map<String, dynamic>> _mockPets = [
  {
    "id": "69b2f858379afab5e51832bb",
    "user_ids": [
      "60d5ec49f1a2c8b1f8e4e1a1"
    ],
    "name": "Luna",
    "species": "Dog",
    "breed": "Golden Retriever",
    "gender": "Female",
    "birth_date": "2020-05-14",
    "weight": 25.5,
    "color": "Golden",
    "photo_url": "https://images.unsplash.com/photo-1633722715463-d30f4f325e24?fm=jpg&q=60&w=3000&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8Z29sZGVuJTIwcmV0cmlldmVyfGVufDB8fDB8fHww",
    "status": "healthy",
    "is_nfc_synced": true,
    "known_allergies": "Pollo",
    "default_vet": "Dr. Smith",
    "default_clinic": "PetCare Clinic",
    "vaccinations": [
      {
        "vaccine_id": "vax_001",
        "date_given": "2023-01-10",
        "next_due_date": "2024-01-10",
        "lot_number": "LT12345",
        "status": "completed",
        "administered_by": "Dr. Smith",
        "attached_documents": [
          {
            "document_id": "doc_001",
            "file_name": "certificado_rabia.pdf",
            "file_uri": "http://ejemplo.com/docs/1"
          }
        ]
      }
    ],
    "events": [
      {
        "event_id": "evt_001",
        "title": "Corte de pelo y baño",
        "event_type": "grooming",
        "date": "2023-10-05",
        "price": 45,
        "provider": "Doggy Style Spa",
        "clinic": "",
        "description": "Baño completo y corte de uñas.",
        "follow_up_date": null,
        "attached_documents": []
      }
    ],
    "notifications": [
      {
        "notification_id": "not_001",
        "type": "vaccination reminder",
        "header": "Vacuna Anual",
        "text": "Es hora de la vacuna contra la rabia de Luna.",
        "date_sent": "2024-01-01T10:00:00+00:00",
        "date_clicked": null
      }
    ]
  },
  {
    "id": "69b2f858379afab5e51832bc",
    "user_ids": [],
    "name": "Milo",
    "species": "Cat",
    "breed": "Siamés",
    "gender": "Male",
    "birth_date": "2021-08-20",
    "weight": 4.2,
    "color": "Crema y Marrón",
    "photo_url": null,
    "status": "lost",
    "is_nfc_synced": false,
    "known_allergies": "Ninguna",
    "default_vet": "",
    "default_clinic": "",
    "vaccinations": [],
    "events": [
      {
        "event_id": "evt_002",
        "title": "Consulta por dolor estomacal",
        "event_type": "vet visit",
        "date": "2023-11-20",
        "price": 60,
        "provider": "Dra. Gomez",
        "clinic": "GatosFelices",
        "description": "Milo comió algo en mal estado. Se recetó dieta blanda.",
        "follow_up_date": "2023-11-25",
        "attached_documents": [
          {
            "document_id": "doc_002",
            "file_name": "receta_dieta.jpg",
            "file_uri": "http://ejemplo.com/docs/2"
          }
        ]
      }
    ],
    "notifications": []
  },
  {
    "id": "69b2f858379afab5e51832bd",
    "user_ids": [],
    "name": "Bella",
    "species": "Dog",
    "breed": "Bulldog Francés",
    "gender": "Female",
    "birth_date": "2022-02-10",
    "weight": 12,
    "color": "Blanco y Negro",
    "photo_url": null,
    "status": "healthy",
    "is_nfc_synced": true,
    "known_allergies": "",
    "default_vet": "",
    "default_clinic": "",
    "vaccinations": [
      {
        "vaccine_id": "vax_002",
        "date_given": "2022-04-15",
        "next_due_date": "2023-04-15",
        "lot_number": "LT9876",
        "status": "overdue",
        "administered_by": "Dr. House",
        "attached_documents": []
      }
    ],
    "events": [],
    "notifications": [
      {
        "notification_id": "not_002",
        "type": "alert",
        "header": "Vacuna Vencida",
        "text": "Bella tiene una vacuna atrasada.",
        "date_sent": "2023-04-16T08:00:00+00:00",
        "date_clicked": null
      }
    ]
  },
  {
    "id": "69b2f859379afab5e51832be",
    "user_ids": [],
    "name": "Rocky",
    "species": "Dog",
    "breed": "Mestizo",
    "gender": "Male",
    "birth_date": "2019-11-01",
    "weight": 18.5,
    "color": "Negro",
    "photo_url": null,
    "status": "healthy",
    "is_nfc_synced": true,
    "known_allergies": "",
    "default_vet": "Vet Center",
    "default_clinic": "",
    "vaccinations": [],
    "events": [],
    "notifications": []
  },
  {
    "id": "69b2f859379afab5e51832bf",
    "user_ids": [],
    "name": "Simba",
    "species": "Cat",
    "breed": "Persa",
    "gender": "Male",
    "birth_date": "2018-07-30",
    "weight": 5.1,
    "color": "Naranja",
    "photo_url": null,
    "status": "healthy",
    "is_nfc_synced": false,
    "known_allergies": "",
    "default_vet": "",
    "default_clinic": "",
    "vaccinations": [
      {
        "vaccine_id": "vax_003",
        "date_given": "2023-05-20",
        "next_due_date": "2024-05-20",
        "lot_number": "LT5555",
        "status": "completed",
        "administered_by": "Cat Care Clinic",
        "attached_documents": []
      }
    ],
    "events": [],
    "notifications": []
  }
];