import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

void main() {
  runApp(const MyApp());
}

class Medicine {
  String name;
  String dose;
  TimeOfDay time;
  String type;
  String? imagePath;

  Medicine({
    required this.name,
    required this.dose,
    required this.time,
    required this.type,
    this.imagePath,
  });
}

class MedicineNotifier extends ChangeNotifier {
  List<Medicine> medicines = [];

  void addMedicine(Medicine medicine) {
    medicines.add(medicine);
    notifyListeners();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MedicineNotifier(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Recordatorio de Medicamentos',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.teal),
          fontFamily: 'Roboto',
        ),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordatorio de Medicamentos'),
        backgroundColor: Colors.teal,
      ),
      body: const MedicineList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddMedicinePage()),
          );
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MedicineList extends StatelessWidget {
  const MedicineList({Key? key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicineNotifier>(
      builder: (context, medicineNotifier, child) {
        return ListView.builder(
          itemCount: medicineNotifier.medicines.length,
          itemBuilder: (context, index) {
            Medicine medicine = medicineNotifier.medicines[index];
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                title: Text(
                  medicine.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dosis: ${medicine.dose}',
                        style: const TextStyle(fontSize: 14)),
                    Text('Tiempo que empezo: ${medicine.time.format(context)}',
                        style: const TextStyle(fontSize: 14)),
                    Text('Tipo: ${medicine.type}'),
                    //Muestra la imagen si la ruta no es nula
                    if (medicine.imagePath != null)
                      Image.file(File(medicine.imagePath!))
                  ],
                ),
                leading: Image.asset(
                  'assets/${medicine.type.toLowerCase()}.png',
                  width: 50,
                  height: 50,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class AddMedicinePage extends StatefulWidget {
  AddMedicinePage({Key? key});

  @override
  _AddMedicinePageState createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController doseController = TextEditingController();
  final TextEditingController intervaloController = TextEditingController();
  Image? previewImage;
  TimeOfDay? selectedTime;
  String selectedType = 'pildoras';
  String? imagePath;

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      selectedTime = picked;
    }
  }

  Future<void> _takePicture() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      final Directory appDirectory = await getApplicationDocumentsDirectory();
      final String picturePath =
          '${appDirectory.path}/${DateTime.now().toIso8601String()}.png';
      final File savedImage = await File(photo.path).copy(picturePath);

      setState(() {
        previewImage = Image.file(savedImage);
        // Guarda la ruta de la imagen para su uso posterior
        imagePath =
            picturePath; // Asegúrate de tener una variable imagePath o similar para almacenarlo
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    tz.initializeTimeZones();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Medicamento'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Indique el nombre del medicamento',
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: doseController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cual es la dosis asignada?',
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: intervaloController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText:
                            'Cada cuanto tiempo debe tomar? (en minutos)',
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: selectedType,
              hint: const Text('Seleccione el tipo de medicina',
                  style: TextStyle(color: Colors.white)),
              onChanged: (String? newValue) {
                setState(() {
                  selectedType = newValue!;
                });
              },
              items: <String>['pildoras', 'jeringa', 'jarabe', 'tabletas']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/${value.toLowerCase()}.png',
                        width: 30,
                        height: 30,
                      ),
                      const SizedBox(width: 10),
                      Text(value),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tiempo Inicial: ${selectedTime?.format(context) ?? ""}'),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _selectTime(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                textStyle: const TextStyle(color: Colors.white),
              ),
              child: const Text('Selecciona el tiempo de inicio',
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _takePicture,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
              child: const Text('Tomar Foto',
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            // Muestra la vista previa si la imagen no es nula
            if (previewImage != null)
              Container(
                height: 200, // Ajusta según necesites
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: previewImage!.image,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                MedicineNotifier medicineNotifier =
                    context.read<MedicineNotifier>();
                if (selectedTime != null) {
                  Medicine medicine = Medicine(
                    name: nameController.text,
                    dose: doseController.text,
                    time: selectedTime!,
                    type: selectedType,
                    imagePath: imagePath,
                  );
                  int intervalMinutes = int.parse(intervaloController.text);
                  medicineNotifier.addMedicine(medicine);

                  scheduleNotification(medicine, intervalMinutes);
                  Navigator.pop(context);
                } else {
                  // Handle case where no time is selected
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
              child:
                  const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> scheduleNotification(
      Medicine medicine, int intervaloMinutes) async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    AndroidInitializationSettings androidInitializationSettings =
        const AndroidInitializationSettings('app_icon');
    IOSInitializationSettings iosInitializationSettings =
        const IOSInitializationSettings();
    InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    DateTime now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      medicine.time.hour,
      medicine.time.minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    int totalDoses = intervaloMinutes > 0 
        ? (24 * 60) ~/ intervaloMinutes 
        : 0; 
    int currentInterval =
        intervaloMinutes; 

    for (int i = 0; i < totalDoses; i++) {
      scheduledTime = scheduledTime.add(Duration(minutes: currentInterval));
      int notificationId =
          medicine.hashCode + i;
      scheduleSingleNotification(
        flutterLocalNotificationsPlugin,
        scheduledTime,
        medicine,
        notificationId,
      );
      currentInterval +=
          intervaloMinutes; 
    }
  }

  void scheduleSingleNotification(
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
      DateTime scheduledTime,
      Medicine medicine,
      int notificationId) async {
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'Medicine Reminder',
      'Reminds you to take your medicine',
      priority: Priority.high,
      importance: Importance.high,
      ticker: 'ticker',
      styleInformation: medicine.imagePath != null
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(medicine.imagePath!),
              largeIcon: FilePathAndroidBitmap('ic_launcher'),
              contentTitle: 'Recuerda tomar tu dosis de ${medicine.name}!',
              summaryText: 'Dosis: ${medicine.dose} ${medicine.type}',
            )
          : DefaultStyleInformation(true, true),
    );

    IOSNotificationDetails iosNotificationDetails =
        const IOSNotificationDetails();

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'Recuerda tomar tu dosis de ${medicine.name}!',
      'Dosis: ${medicine.dose} ${medicine.type}',
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'scheduled',
    );
  }
}
