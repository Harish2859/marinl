import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class HazardReportingPage extends StatefulWidget {
  const HazardReportingPage({Key? key}) : super(key: key);

  @override
  State<HazardReportingPage> createState() => _HazardReportingPageState();
}

class _HazardReportingPageState extends State<HazardReportingPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // OceanPulse Color Palette
  static const Color deepBlue = Color(0xFF0077B6);
  static const Color turquoise = Color(0xFF00B4D8);
  static const Color coralOrange = Color(0xFFFF6F61);
  static const Color seaGreen = Color(0xFF2EC4B6);
  static const Color lightGray = Color(0xFFF1F5F9);
  static const Color darkNavy = Color(0xFF023047);

  // Form data
  String? selectedEventType;
  Position? currentPosition;
  List<XFile> attachedFiles = [];
  bool isLoadingLocation = false;
  bool isOffline = false;

  // Event types
  final List<String> eventTypes = [
    'Flood',
    'Tsunami',
    'High Wave',
    'Storm Surge',
    'Unusual Tide'
  ];

  // NLP Auto-suggestions based on event type
  final Map<String, List<String>> eventSuggestions = {
    'Flood': [
      'Heavy rainfall causing street flooding',
      'River overflow affecting residential areas',
      'Flash flood from storm drainage backup',
      'Coastal flooding due to high tide',
    ],
    'Tsunami': [
      'Unusual wave patterns observed',
      'Rapid water level changes',
      'Strong undertow and currents',
      'Multiple wave sets approaching',
    ],
    'High Wave': [
      'Waves exceeding normal height',
      'Dangerous surf conditions',
      'Waves causing coastal erosion',
      'Large swells affecting harbor',
    ],
    'Storm Surge': [
      'Rising water levels from storm',
      'Strong winds pushing water inland',
      'Surge flooding low-lying areas',
      'Storm-driven coastal inundation',
    ],
    'Unusual Tide': [
      'Tide levels higher/lower than predicted',
      'Rapid tidal changes',
      'King tide affecting coastal areas',
      'Unusual tidal timing patterns',
    ],
  };

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _getCurrentLocation();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      isOffline = connectivityResult == ConnectivityResult.none;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentPosition = position;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: ${e.toString()}'),
          backgroundColor: coralOrange,
        ),
      );
    } finally {
      setState(() {
        isLoadingLocation = false;
      });
    }
  }

  Future<void> _pickMedia() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera, color: deepBlue),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: deepBlue),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: deepBlue),
                title: const Text('Video'),
                onTap: () {
                  Navigator.pop(context);
                  _getVideo();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          attachedFiles.add(image);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: ${e.toString()}'),
          backgroundColor: coralOrange,
        ),
      );
    }
  }

  Future<void> _getVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
      if (video != null) {
        setState(() {
          attachedFiles.add(video);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick video: ${e.toString()}'),
          backgroundColor: coralOrange,
        ),
      );
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      attachedFiles.removeAt(index);
    });
  }

  void _selectSuggestion(String suggestion) {
    _descriptionController.text = suggestion;
  }

  Future<void> _saveReportLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final reports = prefs.getStringList('offline_reports') ?? [];
    
    final report = {
      'eventType': selectedEventType,
      'description': _descriptionController.text,
      'latitude': currentPosition?.latitude,
      'longitude': currentPosition?.longitude,
      'timestamp': DateTime.now().toIso8601String(),
      'attachments': attachedFiles.map((f) => f.path).toList(),
    };

    reports.add(jsonEncode(report));
    await prefs.setStringList('offline_reports', reports);
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (isOffline) {
      await _saveReportLocally();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report saved locally. Will sync when online.'),
          backgroundColor: seaGreen,
        ),
      );
    } else {
      // TODO: Send to server
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully!'),
          backgroundColor: seaGreen,
        ),
      );
    }

    // Clear form
    setState(() {
      selectedEventType = null;
      _descriptionController.clear();
      attachedFiles.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        title: const Text(
          'Report Hazard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: deepBlue,
        elevation: 0,
        actions: [
          if (isOffline)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: coralOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'OFFLINE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Type Selection
              Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Event Type *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkNavy,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedEventType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: deepBlue),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: turquoise, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select an event type';
                          }
                          return null;
                        },
                        items: eventTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedEventType = newValue;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Description with Auto-suggestions
              Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkNavy,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Describe the hazard...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: deepBlue),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: turquoise, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please provide a description';
                          }
                          return null;
                        },
                      ),
                      
                      // Auto-suggestions
                      if (selectedEventType != null && eventSuggestions[selectedEventType]!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Quick suggestions:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: deepBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: eventSuggestions[selectedEventType]!
                              .map((suggestion) => GestureDetector(
                                    onTap: () => _selectSuggestion(suggestion),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: turquoise.withOpacity(0.1),
                                        border: Border.all(color: turquoise),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        suggestion,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: deepBlue,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Location
              Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: deepBlue),
                          const SizedBox(width: 8),
                          const Text(
                            'Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkNavy,
                            ),
                          ),
                          const Spacer(),
                          if (isLoadingLocation)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(turquoise),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (currentPosition != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: seaGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: seaGreen.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lat: ${currentPosition!.latitude.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 14, color: darkNavy),
                              ),
                              Text(
                                'Lng: ${currentPosition!.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 14, color: darkNavy),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: coralOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: coralOrange.withOpacity(0.3)),
                          ),
                          child: const Text(
                            'Location not available',
                            style: TextStyle(fontSize: 14, color: darkNavy),
                          ),
                        ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.refresh, color: deepBlue),
                        label: const Text(
                          'Update Location',
                          style: TextStyle(color: deepBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Media Attachments
              Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.attach_file, color: deepBlue),
                          const SizedBox(width: 8),
                          const Text(
                            'Photo/Video',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkNavy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Attachment display
                      if (attachedFiles.isNotEmpty) ...[
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: attachedFiles.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(attachedFiles[index].path),
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removeAttachment(index),
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: const BoxDecoration(
                                            color: coralOrange,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      ElevatedButton.icon(
                        onPressed: _pickMedia,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Add Photo/Video'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: turquoise,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: Text(
                    isOffline ? 'Save Report (Offline)' : 'Submit Report',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Offline notice
              if (isOffline)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: coralOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: coralOrange.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off, color: coralOrange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You are offline. Reports will be saved locally and synced when connection is restored.',
                          style: TextStyle(
                            color: darkNavy,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}