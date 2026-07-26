import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/app_http.dart' as http;
import '../viewmodels/profile_viewmodel.dart';
import 'package:geolocator/geolocator.dart';

class DestinationFilterScreen extends StatelessWidget {
  const DestinationFilterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(),
      child: const _DestinationFilterScreenContent(),
    );
  }
}

class _DestinationFilterScreenContent extends StatefulWidget {
  const _DestinationFilterScreenContent();

  @override
  State<_DestinationFilterScreenContent> createState() => _DestinationFilterScreenState();
}

class _DestinationFilterScreenState extends State<_DestinationFilterScreenContent> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  bool _isLoading = false;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().fetchProfile();
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  final String _googleMapsApiKey = 'AIzaSyBEss4wpsQ0o9WPBjDgHsSByUzFuo2oSNE';

  Future<List<Map<String, dynamic>>> _searchAddress(String query) async {
    if (query.isEmpty) return [];
    try {
      final response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_googleMapsApiKey'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(data['predictions']);
        }
      }
    } catch (e) {
      debugPrint('Google Maps API Error: $e');
    }
    return [];
  }

  Future<void> _selectAddress(String placeId, String description) async {
    _addressController.text = description;
    try {
      final response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleMapsApiKey'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          if (result['geometry'] != null) {
            final loc = result['geometry']['location'];
            setState(() {
              _latController.text = loc['lat'].toString();
              _lngController.text = loc['lng'].toString();
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Google Maps Details API Error: $e');
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('driver_token');
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latController.text = position.latitude.toString();
        _lngController.text = position.longitude.toString();
        if (_addressController.text.isEmpty) {
          _addressController.text = 'My Current Location';
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isFetchingLocation = false;
      });
    }
  }

  Future<void> _setDestination() async {
    if (_latController.text.isEmpty || _lngController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Latitude and Longitude are required'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _getToken();
      final body = {
        'address': _addressController.text.isNotEmpty ? _addressController.text : 'Custom Location',
        'latitude': double.parse(_latController.text),
        'longitude': double.parse(_lngController.text),
      };

      final response = await http.post(
        Uri.parse(ApiConstants.setDestination),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final resData = jsonDecode(response.body);

      if (response.statusCode == 200 && resData['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Destination set! Used ${resData['destinationFilterCount']}/4 today.'), backgroundColor: Colors.green),
          );
          context.read<ProfileViewModel>().fetchProfile();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resData['message'] ?? 'Failed to set destination'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error connecting to server'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearDestination() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _getToken();

      final response = await http.post(
        Uri.parse(ApiConstants.clearDestination),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final resData = jsonDecode(response.body);

      if (response.statusCode == 200 && resData['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resData['message'] ?? 'Destination cleared.'), backgroundColor: Colors.green),
          );
          _addressController.clear();
          _latController.clear();
          _lngController.clear();
          context.read<ProfileViewModel>().fetchProfile();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resData['message'] ?? 'Failed to clear destination'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error connecting to server'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.grey900,
        title: const Text('Home-Bound Rides', style: TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Consumer<ProfileViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading && !_isLoading && !_isFetchingLocation) {
            return const Center(child: CircularProgressIndicator(color: AppColors.yellow));
          }

          final driver = vm.driverData;
          final bool hasActiveFilter = driver != null && driver['destinationFilterActive'] == true && driver['preferredDestination'] != null;
          final int filterCount = driver?['destinationFilterCount'] ?? 0;
          final activeDest = hasActiveFilter ? driver['preferredDestination'] : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set a preferred destination up to 4 times a day. We\'ll only send you rides heading in that general direction.',
                  style: TextStyle(color: AppColors.grey400, fontSize: 14),
                ),
                const SizedBox(height: 24),

                if (hasActiveFilter) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Active Destination Filter', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(activeDest['address'] ?? 'Custom Location', style: const TextStyle(color: Colors.green, fontSize: 14)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('Filter Uses Today: $filterCount/4', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                const Text('Destination Address', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Autocomplete<Map<String, dynamic>>(
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
                    return await _searchAddress(textEditingValue.text);
                  },
                  displayStringForOption: (option) => option['description'] ?? '',
                  onSelected: (option) {
                    _selectAddress(option['place_id'], option['description']);
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    if (_addressController.text.isNotEmpty && controller.text.isEmpty) {
                      controller.text = _addressController.text;
                    }
                    // Sync the autocomplete controller with our local address variable
                    controller.addListener(() {
                      _addressController.text = controller.text;
                    });
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: const TextStyle(color: AppColors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g. Noida Sector 62',
                        hintStyle: const TextStyle(color: AppColors.grey600),
                        filled: true,
                        fillColor: AppColors.grey900,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        color: AppColors.grey900,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width - 40,
                            maxHeight: 250,
                          ),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                title: Text(option['description'] ?? '', style: const TextStyle(color: AppColors.white, fontSize: 14)),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Latitude *', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _latController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.white),
                            decoration: InputDecoration(
                              hintText: 'e.g. 28.6139',
                              hintStyle: const TextStyle(color: AppColors.grey600),
                              filled: true,
                              fillColor: AppColors.grey900,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Longitude *', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _lngController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.white),
                            decoration: InputDecoration(
                              hintText: 'e.g. 77.2090',
                              hintStyle: const TextStyle(color: AppColors.grey600),
                              filled: true,
                              fillColor: AppColors.grey900,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isFetchingLocation ? null : _getCurrentLocation,
                    icon: _isFetchingLocation 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.yellow, strokeWidth: 2))
                        : const Icon(Icons.my_location, color: AppColors.yellow, size: 18),
                    label: Text(_isFetchingLocation ? 'Fetching...' : 'Use Current Location', style: const TextStyle(color: AppColors.yellow)),
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _setDestination,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.yellow,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2))
                        : Text(hasActiveFilter ? 'Update Destination' : 'Set Destination', style: const TextStyle(color: AppColors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                if (hasActiveFilter) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _clearDestination,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Clear Filter', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
