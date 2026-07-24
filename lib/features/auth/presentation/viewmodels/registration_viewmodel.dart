import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kwikcabdriver/core/network/app_http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/utils/auth_response.dart';

class RegistrationViewModel extends ChangeNotifier {
  bool isResubmitting = false;

  RegistrationViewModel({Map<String, dynamic>? driverData}) {
    _fetchCarCategories();
    if (driverData != null) {
      isResubmitting = true;
      _prefillData(driverData);
    }
  }

  void _prefillData(Map<String, dynamic> data) {
    name = data['name'] ?? '';
    email = data['email'] ?? '';
    phone = data['phone'] ?? '';
    address = data['address'] ?? '';
    city = data['city'] ?? '';
    state = data['state'] ?? '';
    pincode = data['pincode'] ?? '';
    addressLatitude = data['addressLatitude']?.toString() ?? '';
    addressLongitude = data['addressLongitude']?.toString() ?? '';
    
    licenseNumber = data['licenseNumber'] ?? '';
    licenseExpiry = data['licenseExpiry'] != null ? data['licenseExpiry'].split('T')[0] : '';
    aadharNumber = data['aadharNumber'] ?? '';
    panNumber = data['panNumber'] ?? '';

    final bank = data['bankDetails'] ?? {};
    accountNumber = bank['accountNumber'] ?? '';
    ifscCode = bank['ifscCode'] ?? '';
    accountHolderName = bank['accountHolderName'] ?? '';
    bankName = bank['bankName'] ?? '';

    final car = data['carDetails'] ?? {};
    carNumber = car['carNumber'] ?? '';
    carModel = car['carModel'] ?? '';
    carBrand = car['carBrand'] ?? '';
    carType = car['carType'] ?? '';
    seatCapacity = car['seatCapacity']?.toString() ?? '';
    carColor = car['carColor'] ?? '';
    manufacturingYear = car['manufacturingYear']?.toString() ?? '';
    insuranceExpiry = car['insuranceExpiry'] != null ? car['insuranceExpiry'].split('T')[0] : '';
    permitExpiry = car['permitExpiry'] != null ? car['permitExpiry'].split('T')[0] : '';
    pucExpiry = car['pucExpiry'] != null ? car['pucExpiry'].split('T')[0] : '';
  }

  int _currentStep = 0;
  int get currentStep => _currentStep;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Personal Details
  String name = '';
  String email = '';
  String phone = '';
  String password = '';
  String address = '';
  String city = '';
  String state = '';
  String pincode = '';
  String addressLatitude = '';
  String addressLongitude = '';
  
  // Google Maps API Key
  final String _googleMapsApiKey = 'AIzaSyBEss4wpsQ0o9WPBjDgHsSByUzFuo2oSNE';
  // Document Details
  String licenseNumber = '';
  String licenseExpiry = '';
  String aadharNumber = '';
  String panNumber = '';

  // Bank Details
  String accountNumber = '';
  String ifscCode = '';
  String accountHolderName = '';
  String bankName = '';

  // Car Details
  String carNumber = '';
  String carModel = '';
  String carBrand = '';
  String carType = '';
  String seatCapacity = '';
  String carColor = '';
  String manufacturingYear = '';
  String insuranceExpiry = '';
  String permitExpiry = '';
  String pucExpiry = '';
  List<Map<String, dynamic>> carCategoriesList = [];

  Future<void> _fetchCarCategories() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.carCategories));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['categories'] != null) {
          carCategoriesList = List<Map<String, dynamic>>.from(data['categories']);
          notifyListeners();
        }
      }
    } catch (e) {
      print('Failed to fetch car categories: $e');
    }
  }

  void setCarCategory(String id) {
    carType = id;
    try {
      final category = carCategoriesList.firstWhere((c) => c['_id'] == id);
      seatCapacity = category['seatCapacity']?.toString() ?? '';
    } catch (_) {}
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> searchAddress(String query) async {
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
      print('Google Maps API Error: $e');
    }
    return [];
  }

  Future<void> selectAddress(String placeId, String description) async {
    address = description;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleMapsApiKey'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          
          if (result['geometry'] != null) {
            final loc = result['geometry']['location'];
            addressLatitude = loc['lat'].toString();
            addressLongitude = loc['lng'].toString();
          }

          if (result['address_components'] != null) {
            for (var component in result['address_components']) {
              final types = List<String>.from(component['types']);
              if (types.contains('locality')) city = component['long_name'];
              if (types.contains('administrative_area_level_1')) state = component['long_name'];
              if (types.contains('postal_code')) pincode = component['long_name'];
            }
          }
          notifyListeners();
        }
      }
    } catch (e) {
      print('Google Maps Details API Error: $e');
    }
  }
  // Files
  XFile? image;
  XFile? aadhar;
  XFile? pan;
  XFile? rcImage;
  XFile? insuranceImage;
  XFile? permitImage;
  XFile? pucImage;

  final ImagePicker _picker = ImagePicker();

  void setStep(int step) {
    _currentStep = step;
    _error = null;
    notifyListeners();
  }

  bool validateStep() {
    _error = null;
    switch (_currentStep) {
      case 0: // Personal Details
        if (!isResubmitting && image == null) { _error = 'Profile Photo is required'; return false; }
        if (name.isEmpty || email.isEmpty || phone.isEmpty || (!isResubmitting && password.isEmpty)) {
          _error = 'Please fill all mandatory personal details (Name, Email, Phone' + (isResubmitting ? '' : ', Password') + ')';
          return false;
        }
        if (address.isEmpty || city.isEmpty || state.isEmpty || pincode.isEmpty) {
          _error = 'Please search and select your full address';
          return false;
        }
        if (!isResubmitting && (addressLatitude.isEmpty || addressLongitude.isEmpty)) {
          _error = 'Please select a valid address from the Google Maps suggestions list';
          return false;
        }
        break;
      case 1: // Document Details
        if (aadharNumber.isEmpty || panNumber.isEmpty || licenseNumber.isEmpty || licenseExpiry.isEmpty) {
          _error = 'Please fill all document numbers and expiry dates';
          return false;
        }
        if (!isResubmitting && (aadhar == null || pan == null)) {
          _error = 'Please upload Aadhar and PAN card photos';
          return false;
        }
        break;
      case 2: // Car Details
        if (carNumber.isEmpty || carBrand.isEmpty || carModel.isEmpty || carType.isEmpty || carColor.isEmpty || manufacturingYear.isEmpty) {
          _error = 'Please fill all vehicle details';
          return false;
        }
        if (insuranceExpiry.isEmpty) {
          _error = 'Please fill Insurance expiry date';
          return false;
        }
        if (!isResubmitting && (rcImage == null || insuranceImage == null)) {
          _error = 'RC Book and Insurance photos are mandatory';
          return false;
        }
        break;
      case 3: // Bank Details
        if (bankName.isEmpty || accountHolderName.isEmpty || accountNumber.isEmpty || ifscCode.isEmpty) {
          _error = 'Please fill all bank details';
          return false;
        }
        break;
    }
    return true;
  }

  Future<void> nextStep() async {
    if (validateStep()) {
      if (_currentStep == 0) {
        // Automatically create a Driver Lead when personal details are filled
        try {
          await http.post(
            Uri.parse(ApiConstants.createDriverLead),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'mobile': phone,
              'email': email,
            }),
          );
        } catch (e) {
          print('Failed to create driver lead: $e');
        }
      }

      if (_currentStep < 3) {
        _currentStep++;
        _error = null;
        notifyListeners();
      }
    } else {
      notifyListeners();
    }
  }

  void prevStep() {
    if (_currentStep > 0) {
      _currentStep--;
      _error = null;
      notifyListeners();
    }
  }

  Future<void> pickImage(String field, ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        switch (field) {
          case 'image': image = pickedFile; break;
          case 'aadhar': aadhar = pickedFile; break;
          case 'pan': pan = pickedFile; break;
          case 'rcImage': rcImage = pickedFile; break;
          case 'insuranceImage': insuranceImage = pickedFile; break;
          case 'permitImage': permitImage = pickedFile; break;
          case 'pucImage': pucImage = pickedFile; break;
        }
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to pick image: $e';
      notifyListeners();
    }
  }

  Future<AuthResponse> submitRegistration() async {
    if (!validateStep()) {
      notifyListeners();
      return AuthResponse(status: LoginStatus.invalidCredentials, message: _error!);
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final endpoint = isResubmitting ? ApiConstants.driverResubmit : ApiConstants.driverRegister;
      var request = http.MultipartRequest('POST', Uri.parse(endpoint));

      // Add Text Fields
      final fields = {
        'name': name, 'email': email, 'phone': phone, 'password': password,
        'address': address, 'city': city, 'state': state, 'pincode': pincode,
        'addressLatitude': addressLatitude, 'addressLongitude': addressLongitude,
        'licenseNumber': licenseNumber, 'licenseExpiry': licenseExpiry,
        'aadharNumber': aadharNumber, 'panNumber': panNumber,
        'accountNumber': accountNumber, 'ifscCode': ifscCode,
        'accountHolderName': accountHolderName, 'bankName': bankName,
        'carNumber': carNumber, 'carModel': carModel, 'carBrand': carBrand,
        'carType': carType, 'seatCapacity': seatCapacity, 'carColor': carColor,
        'manufacturingYear': manufacturingYear, 'insuranceExpiry': insuranceExpiry,
        'permitExpiry': permitExpiry, 'pucExpiry': pucExpiry,
      };

      fields.forEach((key, value) {
        if (value.isNotEmpty) {
          request.fields[key] = value;
        }
      });

      // Add Files
      if (image != null) request.files.add(await http.MultipartFile.fromPath('image', image!.path));
      if (aadhar != null) request.files.add(await http.MultipartFile.fromPath('aadhar', aadhar!.path));
      if (pan != null) request.files.add(await http.MultipartFile.fromPath('pan', pan!.path));
      if (rcImage != null) request.files.add(await http.MultipartFile.fromPath('rcImage', rcImage!.path));
      if (insuranceImage != null) request.files.add(await http.MultipartFile.fromPath('insuranceImage', insuranceImage!.path));
      if (permitImage != null) request.files.add(await http.MultipartFile.fromPath('permitImage', permitImage!.path));
      if (pucImage != null) request.files.add(await http.MultipartFile.fromPath('pucImage', pucImage!.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      dynamic responseBody;
      try {
        responseBody = jsonDecode(response.body);
      } catch (_) {
        _isLoading = false;
        _error = 'Server returned invalid response (Error ${response.statusCode})';
        notifyListeners();
        return AuthResponse(status: LoginStatus.serverError, message: _error!);
      }

      final int statusCode = response.statusCode;
      String message = responseBody['message'] ?? 'Unknown error';
      if (responseBody['error'] != null) {
        message += ' (${responseBody['error']})';
      }

      _isLoading = false;
      notifyListeners();

      if (statusCode == 201 || (statusCode == 200 && responseBody['success'] == true)) {
        return AuthResponse(status: LoginStatus.pending, message: message, data: responseBody['driver']);
      } else {
        _error = message;
        return AuthResponse(status: LoginStatus.serverError, message: message);
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to connect to server. Please try again.';
      notifyListeners();
      return AuthResponse(status: LoginStatus.networkError, message: _error!);
    }
  }
}
