import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kwikcabdriver/core/network/app_http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_constants.dart';

class EditProfileViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Personal Info
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
  File? image;

  // Documents
  String aadharNumber = '';
  String panNumber = '';
  String licenseNumber = '';
  String licenseExpiry = '';
  File? aadhar;
  File? pan;
  File? licenseImage; // Reusing logic from registration, wait, registration didn't have licenseImage file but backend has it? Backend updateDriverProfile accepts `license`, `aadhar`, `pan`. Registration did not have licenseImage upload.

  // Car Details
  String carNumber = '';
  String carBrand = '';
  String carModel = '';
  String carType = '';
  String seatCapacity = '';
  String carColor = '';
  String manufacturingYear = '';
  String insuranceExpiry = '';
  String permitExpiry = '';
  String pucExpiry = '';
  
  File? rcImage;
  File? insuranceImage;
  File? permitImage;
  File? pucImage;

  // Bank Details
  String bankName = '';
  String accountHolderName = '';
  String accountNumber = '';
  String ifscCode = '';

  List<dynamic> carCategoriesList = [];

  EditProfileViewModel(Map<String, dynamic>? initialData) {
    if (initialData != null) {
      _initializeData(initialData);
    }
    _fetchCarCategories();
  }

  void _initializeData(Map<String, dynamic> data) {
    name = data['name'] ?? '';
    email = data['email'] ?? '';
    phone = data['phone'] ?? '';
    address = data['address'] ?? '';
    city = data['city'] ?? '';
    state = data['state'] ?? '';
    pincode = data['pincode'] ?? '';
    addressLatitude = data['addressLatitude']?.toString() ?? '';
    addressLongitude = data['addressLongitude']?.toString() ?? '';
    
    aadharNumber = data['aadharNumber'] ?? '';
    panNumber = data['panNumber'] ?? '';
    licenseNumber = data['licenseNumber'] ?? '';
    licenseExpiry = data['licenseExpiry'] != null ? data['licenseExpiry'].split('T')[0] : '';
    
    final bank = data['bankDetails'] ?? {};
    bankName = bank['bankName'] ?? '';
    accountHolderName = bank['accountHolderName'] ?? '';
    accountNumber = bank['accountNumber'] ?? '';
    ifscCode = bank['ifscCode'] ?? '';

    final car = data['carDetails'] ?? {};
    carNumber = car['carNumber'] ?? '';
    carBrand = car['carBrand'] ?? '';
    carModel = car['carModel'] ?? '';
    carType = car['carType'] ?? '';
    carColor = car['carColor'] ?? '';
    manufacturingYear = car['manufacturingYear']?.toString() ?? '';
    insuranceExpiry = car['insuranceExpiry'] != null ? car['insuranceExpiry'].split('T')[0] : '';
    permitExpiry = car['permitExpiry'] != null ? car['permitExpiry'].split('T')[0] : '';
    pucExpiry = car['pucExpiry'] != null ? car['pucExpiry'].split('T')[0] : '';
  }

  Future<void> _fetchCarCategories() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.carCategories));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          carCategoriesList = data['categories'];
          
          if (carType.isNotEmpty) {
            final cat = carCategoriesList.firstWhere((c) => c['_id'] == carType, orElse: () => null);
            if (cat != null) {
              seatCapacity = cat['seats'].toString();
            }
          }
          notifyListeners();
        }
      }
    } catch (e) {
      // Ignore
    }
  }

  void setCarCategory(String id) {
    carType = id;
    final cat = carCategoriesList.firstWhere((c) => c['_id'] == id, orElse: () => null);
    if (cat != null) {
      seatCapacity = cat['seats'].toString();
    }
    notifyListeners();
  }

  Future<void> pickImage(String field, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        switch (field) {
          case 'image': image = file; break;
          case 'aadhar': aadhar = file; break;
          case 'pan': pan = file; break;
          case 'license': licenseImage = file; break;
          case 'rcImage': rcImage = file; break;
          case 'insuranceImage': insuranceImage = file; break;
          case 'permitImage': permitImage = file; break;
          case 'pucImage': pucImage = file; break;
        }
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to pick image';
      notifyListeners();
    }
  }

  Future<bool> updateProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token');

      var request = http.MultipartRequest('PUT', Uri.parse(ApiConstants.profileUpdate));
      request.headers['Authorization'] = 'Bearer $token';

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

      if (image != null) request.files.add(await http.MultipartFile.fromPath('image', image!.path));
      if (aadhar != null) request.files.add(await http.MultipartFile.fromPath('aadhar', aadhar!.path));
      if (pan != null) request.files.add(await http.MultipartFile.fromPath('pan', pan!.path));
      // License photo upload is not supported by backend multer config yet, so we skip it to prevent 500 HTML errors
      // if (licenseImage != null) request.files.add(await http.MultipartFile.fromPath('license', licenseImage!.path));
      if (rcImage != null) request.files.add(await http.MultipartFile.fromPath('rcImage', rcImage!.path));
      if (insuranceImage != null) request.files.add(await http.MultipartFile.fromPath('insuranceImage', insuranceImage!.path));
      if (permitImage != null) request.files.add(await http.MultipartFile.fromPath('permitImage', permitImage!.path));
      if (pucImage != null) request.files.add(await http.MultipartFile.fromPath('pucImage', pucImage!.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var responseBody = jsonDecode(response.body);

      _isLoading = false;
      if (response.statusCode == 200 && responseBody['success'] == true) {
        notifyListeners();
        return true;
      } else {
        _error = responseBody['message'] ?? 'Failed to update profile';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Network error: $e';
      notifyListeners();
      return false;
    }
  }
}
