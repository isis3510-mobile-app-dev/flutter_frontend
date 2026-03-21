import '../../app/routes.dart';

/// Map route names to the corresponding Screen _id in your telemetry DB.
/// Fill in the ObjectId strings for each route you want to track.
const Map<String, String> screenIdByRoute = {
  Routes.authGate: '69bc15e9bf153df7a2f41abd',
  Routes.auth: '69bc15e9bf153df7a2f41abd',
  Routes.welcomePage: '69b782f1640b7b908f640c81',
  Routes.home: '69bc15e9bf153df7a2f41abe',
  Routes.pets: '69bc15e9bf153df7a2f41abf',
  Routes.addPet: '69bc15e9bf153df7a2f41ac1',
  Routes.petDetail: '69bc15e9bf153df7a2f41ac0',
  Routes.addVaccine: '69bc15e9bf153df7a2f41ac2',
  Routes.addEvent: '69bc15e9bf153df7a2f41ac3',
  Routes.records: '69bc15e9bf153df7a2f41ac4',
  Routes.smartAlerts: '69bc1667bf153df7a2f41ac8',
  Routes.calendar: '69bc1667bf153df7a2f41ac6',
  Routes.profile: '69bc1667bf153df7a2f41ac9',
  Routes.profileEdit: '69bc1667bf153df7a2f41aca',
  Routes.nfc: '69bc1667bf153df7a2f41ac7',
  Routes.vaccineDetail: '69bc1667bf153df7a2f41ac5',
  Routes.eventDetail: '69bc1667bf153df7a2f41ac5',
};
