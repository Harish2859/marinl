import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'dart:async';
import 'dart:math';

// Custom colors based on your ocean theme
class AppColors {
  static const Color deepBlue = Color(0xFF0077B6);
  static const Color turquoise = Color(0xFF00B4D8);
  static const Color coralOrange = Color(0xFFFF6F61);
  static const Color seaGreen = Color(0xFF2EC4B6);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF1F5F9);
  static const Color darkNavy = Color(0xFF023047);
}

// Report model
class WaterReport {
  final String id;
  final LatLng location;
  final String title;
  final String description;
  final ReportType type;
  final SeverityLevel severity;
  final DateTime timestamp;
  final bool isVerified;

  WaterReport({
    required this.id,
    required this.location,
    required this.title,
    required this.description,
    required this.type,
    required this.severity,
    required this.timestamp,
    this.isVerified = false,
  });
}

enum ReportType {
  pollution,
  safety,
  wildlife,
  infrastructure,
  weather,
}

enum SeverityLevel {
  low,
  medium,
  high,
  critical,
}

// Filter options
class MapFilters {
  Set<ReportType> eventTypes;
  Set<SeverityLevel> severityLevels;
  DateTimeRange? timeRange;

  MapFilters({
    Set<ReportType>? eventTypes,
    Set<SeverityLevel>? severityLevels,
    this.timeRange,
  }) : 
    eventTypes = eventTypes ?? Set.from(ReportType.values),
    severityLevels = severityLevels ?? Set.from(SeverityLevel.values);
}

class ReportsMapView extends StatefulWidget {
  @override
  _ReportsMapViewState createState() => _ReportsMapViewState();
}

class _ReportsMapViewState extends State<ReportsMapView> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Set<Marker> _hotspotMarkers = {};
  MapFilters _filters = MapFilters();
  List<WaterReport> _allReports = [];
  List<WaterReport> _filteredReports = [];

  @override
  void initState() {
    super.initState();
    _generateSampleData();
    _applyFilters();
  }

  void _generateSampleData() {
    final random = Random();
    final baseLocation = LatLng(40.7128, -74.0060); // NYC coordinates
    
    _allReports = List.generate(50, (index) {
      return WaterReport(
        id: 'report_$index',
        location: LatLng(
          baseLocation.latitude + (random.nextDouble() - 0.5) * 0.1,
          baseLocation.longitude + (random.nextDouble() - 0.5) * 0.1,
        ),
        title: _getRandomTitle(ReportType.values[random.nextInt(ReportType.values.length)]),
        description: 'Sample report description for incident $index',
        type: ReportType.values[random.nextInt(ReportType.values.length)],
        severity: SeverityLevel.values[random.nextInt(SeverityLevel.values.length)],
        timestamp: DateTime.now().subtract(Duration(days: random.nextInt(30))),
        isVerified: random.nextBool(),
      );
    });
  }

  String _getRandomTitle(ReportType type) {
    final titles = {
      ReportType.pollution: ['Oil Spill Detected', 'Chemical Discharge', 'Plastic Debris'],
      ReportType.safety: ['Strong Current Warning', 'Sharp Objects', 'Unsafe Swimming'],
      ReportType.wildlife: ['Jellyfish Bloom', 'Shark Sighting', 'Dead Fish'],
      ReportType.infrastructure: ['Broken Pier', 'Damaged Seawall', 'Flooding'],
      ReportType.weather: ['Storm Warning', 'High Waves', 'Dangerous Winds'],
    };
    
    final typeList = titles[type] ?? ['General Report'];
    return typeList[Random().nextInt(typeList.length)];
  }

  void _applyFilters() {
    setState(() {
      _filteredReports = _allReports.where((report) {
        bool matchesType = _filters.eventTypes.contains(report.type);
        bool matchesSeverity = _filters.severityLevels.contains(report.severity);
        bool matchesTime = _filters.timeRange == null ||
            (report.timestamp.isAfter(_filters.timeRange!.start) &&
             report.timestamp.isBefore(_filters.timeRange!.end));
        
        return matchesType && matchesSeverity && matchesTime;
      }).toList();

      _updateMarkers();
      _generateHotspots();
    });
  }

  void _updateMarkers() {
    _markers = _filteredReports.map((report) {
      return Marker(
        markerId: MarkerId(report.id),
        position: report.location,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getMarkerColor(report.type, report.severity),
        ),
        infoWindow: InfoWindow(
          title: report.title,
          snippet: '${_getTypeString(report.type)} • ${_getSeverityString(report.severity)}',
          onTap: () => _showReportDetails(report),
        ),
      );
    }).toSet();
  }

  double _getMarkerColor(ReportType type, SeverityLevel severity) {
    // Base color on severity, with type variations
    switch (severity) {
      case SeverityLevel.critical:
        return BitmapDescriptor.hueRed;
      case SeverityLevel.high:
        return BitmapDescriptor.hueOrange;
      case SeverityLevel.medium:
        return BitmapDescriptor.hueYellow;
      case SeverityLevel.low:
        return BitmapDescriptor.hueGreen;
    }
  }

  void _generateHotspots() {
    // Simple clustering logic - group nearby reports
    Map<String, List<WaterReport>> clusters = {};
    const double clusterRadius = 0.01; // degrees
    
    for (var report in _filteredReports) {
      String clusterKey = '${(report.location.latitude / clusterRadius).round()}_${(report.location.longitude / clusterRadius).round()}';
      
      if (!clusters.containsKey(clusterKey)) {
        clusters[clusterKey] = [];
      }
      clusters[clusterKey]!.add(report);
    }

    // Create hotspot markers for clusters with 3+ reports
    _hotspotMarkers = clusters.entries.where((entry) => entry.value.length >= 3).map((entry) {
      var reports = entry.value;
      var centerLat = reports.map((r) => r.location.latitude).reduce((a, b) => a + b) / reports.length;
      var centerLng = reports.map((r) => r.location.longitude).reduce((a, b) => a + b) / reports.length;
      
      return Marker(
        markerId: MarkerId('hotspot_${entry.key}'),
        position: LatLng(centerLat, centerLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          reports.any((r) => r.severity == SeverityLevel.critical || r.severity == SeverityLevel.high)
              ? BitmapDescriptor.hueRed
              : BitmapDescriptor.hueOrange,
        ),
        infoWindow: InfoWindow(
          title: 'Hotspot Area',
          snippet: '${reports.length} reports in this area',
        ),
      );
    }).toSet();
  }

  String _getTypeString(ReportType type) {
    switch (type) {
      case ReportType.pollution:
        return 'Pollution';
      case ReportType.safety:
        return 'Safety';
      case ReportType.wildlife:
        return 'Wildlife';
      case ReportType.infrastructure:
        return 'Infrastructure';
      case ReportType.weather:
        return 'Weather';
    }
  }

  String _getSeverityString(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.low:
        return 'Low';
      case SeverityLevel.medium:
        return 'Medium';
      case SeverityLevel.high:
        return 'High';
      case SeverityLevel.critical:
        return 'Critical';
    }
  }

  void _showReportDetails(WaterReport report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildReportDetailsSheet(report),
    );
  }

  Widget _buildReportDetailsSheet(WaterReport report) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getSeverityColor(report.severity),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getSeverityString(report.severity),
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(width: 8),
              if (report.isVerified)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.seaGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: AppColors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            report.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkNavy,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.category, color: AppColors.turquoise, size: 16),
              SizedBox(width: 8),
              Text(
                _getTypeString(report.type),
                style: TextStyle(
                  color: AppColors.deepBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 16),
              Icon(Icons.access_time, color: AppColors.turquoise, size: 16),
              SizedBox(width: 8),
              Text(
                '${report.timestamp.day}/${report.timestamp.month}/${report.timestamp.year}',
                style: TextStyle(color: AppColors.deepBlue),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            report.description,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.darkNavy,
              height: 1.4,
            ),
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepBlue,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('View Full Report'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.deepBlue,
                    side: BorderSide(color: AppColors.deepBlue),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Get Directions'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.critical:
        return Colors.red[700]!;
      case SeverityLevel.high:
        return AppColors.coralOrange;
      case SeverityLevel.medium:
        return Colors.orange[600]!;
      case SeverityLevel.low:
        return AppColors.seaGreen;
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Reports',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filters = MapFilters();
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Clear All',
                      style: TextStyle(color: AppColors.coralOrange),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              
              // Event Type Filters
              Text(
                'Event Types',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkNavy,
                ),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ReportType.values.map((type) {
                  bool isSelected = _filters.eventTypes.contains(type);
                  return FilterChip(
                    label: Text(_getTypeString(type)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setSheetState(() {
                        if (selected) {
                          _filters.eventTypes.add(type);
                        } else {
                          _filters.eventTypes.remove(type);
                        }
                      });
                    },
                    selectedColor: AppColors.turquoise.withOpacity(0.3),
                    checkmarkColor: AppColors.deepBlue,
                  );
                }).toList(),
              ),
              
              SizedBox(height: 24),
              
              // Severity Filters
              Text(
                'Severity Levels',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkNavy,
                ),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SeverityLevel.values.map((severity) {
                  bool isSelected = _filters.severityLevels.contains(severity);
                  return FilterChip(
                    label: Text(_getSeverityString(severity)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setSheetState(() {
                        if (selected) {
                          _filters.severityLevels.add(severity);
                        } else {
                          _filters.severityLevels.remove(severity);
                        }
                      });
                    },
                    selectedColor: _getSeverityColor(severity).withOpacity(0.3),
                    checkmarkColor: _getSeverityColor(severity),
                  );
                }).toList(),
              ),
              
              SizedBox(height: 24),
              
              // Time Range Filter
              Text(
                'Time Range',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkNavy,
                ),
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    DateTimeRange? picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(Duration(days: 365)),
                      lastDate: DateTime.now(),
                      initialDateRange: _filters.timeRange,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                              primary: AppColors.deepBlue,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setSheetState(() {
                        _filters.timeRange = picked;
                      });
                    }
                  },
                  icon: Icon(Icons.date_range),
                  label: Text(
                    _filters.timeRange != null
                        ? '${_filters.timeRange!.start.day}/${_filters.timeRange!.start.month} - ${_filters.timeRange!.end.day}/${_filters.timeRange!.end.month}'
                        : 'Select Date Range',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.deepBlue,
                    side: BorderSide(color: AppColors.deepBlue),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              if (_filters.timeRange != null) ...[
                SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setSheetState(() {
                      _filters.timeRange = null;
                    });
                  },
                  child: Text(
                    'Clear Date Range',
                    style: TextStyle(color: AppColors.coralOrange),
                  ),
                ),
              ],
              
              Spacer(),
              
              // Apply Filters Button
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepBlue,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Apply Filters (${_filteredReports.length} reports)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Reports Map',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _showFilterSheet,
            icon: Stack(
              children: [
                Icon(Icons.filter_list),
                if (_isFilterActive())
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.coralOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Toggle layer view (could show/hide hotspots)
            },
            icon: Icon(Icons.layers),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(40.7128, -74.0060),
              zoom: 12,
            ),
            markers: {..._markers, ..._hotspotMarkers},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          
          // Stats overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Total Reports',
                    '${_filteredReports.length}',
                    Icons.report_problem,
                    AppColors.deepBlue,
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: AppColors.lightGray,
                  ),
                  _buildStatItem(
                    'Hotspots',
                    '${_hotspotMarkers.length}',
                    Icons.warning,
                    AppColors.coralOrange,
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: AppColors.lightGray,
                  ),
                  _buildStatItem(
                    'Verified',
                    '${_filteredReports.where((r) => r.isVerified).length}',
                    Icons.verified,
                    AppColors.seaGreen,
                  ),
                ],
              ),
            ),
          ),
          
          // My Location Button
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              onPressed: () async {
                // Get current location and move camera
                // This would require location permissions
              },
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.deepBlue,
              mini: true,
              child: Icon(Icons.my_location),
            ),
          ),
          
          // Add Report Button
          Positioned(
            bottom: 20,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                // Navigate to add report screen
              },
              backgroundColor: AppColors.coralOrange,
              foregroundColor: AppColors.white,
              icon: Icon(Icons.add),
              label: Text('Report Issue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkNavy,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.deepBlue,
          ),
        ),
      ],
    );
  }

  bool _isFilterActive() {
    return _filters.eventTypes.length != ReportType.values.length ||
           _filters.severityLevels.length != SeverityLevel.values.length ||
           _filters.timeRange != null;
  }
}