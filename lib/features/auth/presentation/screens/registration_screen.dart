import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/auth_response.dart';
import '../../../../routes/app_routes.dart';
import '../viewmodels/registration_viewmodel.dart';

class RegistrationScreen extends StatelessWidget {
  final Map<String, dynamic>? driverData;
  const RegistrationScreen({super.key, this.driverData});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegistrationViewModel(driverData: driverData),
      child: const _RegistrationView(),
    );
  }
}

class _RegistrationView extends StatelessWidget {
  const _RegistrationView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegistrationViewModel>();

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
          onPressed: () {
            if (vm.currentStep > 0) {
              vm.prevStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Driver Registration', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Custom Stepper Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _stepIndicator(0, 'Personal', vm.currentStep),
                _stepDivider(),
                _stepIndicator(1, 'Documents', vm.currentStep),
                _stepDivider(),
                _stepIndicator(2, 'Car', vm.currentStep),
                _stepDivider(),
                _stepIndicator(3, 'Bank', vm.currentStep),
              ],
            ),
          ),
          
          if (vm.error != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(vm.error!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500))),
                ],
              ),
            ),

          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildCurrentStep(context, vm),
            ),
          ),

          // Bottom Buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.black,
              border: Border(top: BorderSide(color: AppColors.grey600.withOpacity(0.2))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (vm.currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.white,
                          side: const BorderSide(color: AppColors.grey500),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: vm.prevStep,
                        child: const Text('Back', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (vm.currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellow,
                        foregroundColor: AppColors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: vm.isLoading ? null : () async {
                        if (vm.currentStep < 3) {
                          vm.nextStep();
                        } else {
                          final response = await vm.submitRegistration();
                          if (context.mounted && response.status == LoginStatus.pending) {
                            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.pending, (route) => false, arguments: {'message': response.message});
                          }
                        }
                      },
                      child: vm.isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.black))
                          : Text(vm.currentStep < 3 ? 'Next Step' : 'Submit Registration', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepIndicator(int stepIndex, String title, int currentStep) {
    final isActive = stepIndex <= currentStep;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.yellow : AppColors.grey600.withOpacity(0.3),
          ),
          alignment: Alignment.center,
          child: Text('${stepIndex + 1}', style: TextStyle(color: isActive ? AppColors.black : AppColors.grey500, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 12, color: isActive ? AppColors.white : AppColors.grey500, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }

  Widget _stepDivider() {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24, left: 8, right: 8),
        color: AppColors.grey600.withOpacity(0.3),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context, RegistrationViewModel vm) {
    switch (vm.currentStep) {
      case 0: return _buildPersonalDetails(vm);
      case 1: return _buildDocumentDetails(context, vm);
      case 2: return _buildCarDetails(context, vm);
      case 3: return _buildBankDetails(vm);
      default: return const SizedBox();
    }
  }

  Widget _buildPersonalDetails(RegistrationViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Personal Details', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _imagePickerTile('Profile Photo', vm.image, (source) => vm.pickImage('image', source)),
        const SizedBox(height: 16),
        _textField(label: 'Full Name*', hint: 'Enter full name', initialValue: vm.name, onChanged: (v) => vm.name = v),
        _textField(label: 'Email*', hint: 'Enter email address', keyboardType: TextInputType.emailAddress, initialValue: vm.email, readOnly: vm.isResubmitting, onChanged: (v) => vm.email = v),
        _textField(label: 'Phone Number*', hint: 'Enter 10-digit phone', keyboardType: TextInputType.phone, initialValue: vm.phone, readOnly: vm.isResubmitting, onChanged: (v) => vm.phone = v),
        _textField(label: 'Password*', hint: 'Create a password', obscureText: true, initialValue: vm.password, onChanged: (v) => vm.password = v),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Autocomplete<Map<String, dynamic>>(
            optionsBuilder: (TextEditingValue textEditingValue) async {
              if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
              return await vm.searchAddress(textEditingValue.text);
            },
            displayStringForOption: (option) => option['description'] ?? '',
            onSelected: (option) {
              vm.selectAddress(option['place_id'], option['description']);
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              if (vm.address.isNotEmpty && controller.text.isEmpty) {
                controller.text = vm.address;
              }
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                onChanged: (v) => vm.address = v,
                style: const TextStyle(color: AppColors.white, fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Address',
                  labelStyle: const TextStyle(color: AppColors.grey500, fontSize: 14),
                  hintText: 'Search your address',
                  hintStyle: TextStyle(color: AppColors.grey600.withOpacity(0.5), fontSize: 14),
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  filled: true,
                  fillColor: AppColors.black,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.grey600, width: 1)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.yellow, width: 2)),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: AppColors.grey900,
                  elevation: 4,
                  borderRadius: BorderRadius.circular(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 48,
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
        ),
        Row(
          children: [
            Expanded(child: _textField(key: ValueKey('city_${vm.city}'), label: 'City', hint: 'Auto-filled', initialValue: vm.city, onChanged: (v) => vm.city = v, readOnly: true)),
            const SizedBox(width: 16),
            Expanded(child: _textField(key: ValueKey('state_${vm.state}'), label: 'State', hint: 'Auto-filled', initialValue: vm.state, onChanged: (v) => vm.state = v, readOnly: true)),
          ],
        ),
        _textField(key: ValueKey('pin_${vm.pincode}'), label: 'Pincode', hint: 'Auto-filled', keyboardType: TextInputType.number, initialValue: vm.pincode, onChanged: (v) => vm.pincode = v, readOnly: true),
      ],
    );
  }

  Widget _buildDocumentDetails(BuildContext context, RegistrationViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Document Uploads', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _textField(label: 'Aadhar Number*', hint: '12-digit Aadhar number', keyboardType: TextInputType.number, initialValue: vm.aadharNumber, onChanged: (v) => vm.aadharNumber = v),
        _imagePickerTile('Aadhar Card Photo*', vm.aadhar, (source) => vm.pickImage('aadhar', source)),
        const SizedBox(height: 24),
        _textField(label: 'PAN Number*', hint: '10-character PAN', initialValue: vm.panNumber, onChanged: (v) => vm.panNumber = v),
        _imagePickerTile('PAN Card Photo*', vm.pan, (source) => vm.pickImage('pan', source)),
        const SizedBox(height: 24),
        _textField(label: 'Driving License Number*', hint: 'DL Number', initialValue: vm.licenseNumber, onChanged: (v) => vm.licenseNumber = v),
        _dateField(context: context, label: 'License Expiry*', hint: 'YYYY-MM-DD', initialValue: vm.licenseExpiry, onChanged: (v) => vm.licenseExpiry = v),
      ],
    );
  }

  Widget _buildCarDetails(BuildContext context, RegistrationViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vehicle Details', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _textField(label: 'Car Number*', hint: 'e.g., UP32AB1234', initialValue: vm.carNumber, onChanged: (v) => vm.carNumber = v),
        Row(
          children: [
            Expanded(child: _textField(label: 'Brand*', hint: 'e.g., Maruti', initialValue: vm.carBrand, onChanged: (v) => vm.carBrand = v)),
            const SizedBox(width: 16),
            Expanded(child: _textField(label: 'Model*', hint: 'e.g., Dzire', initialValue: vm.carModel, onChanged: (v) => vm.carModel = v)),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: vm.carType.isNotEmpty && vm.carCategoriesList.any((c) => c['_id'] == vm.carType) ? vm.carType : null,
                  hint: const Text('Select Type', style: TextStyle(color: AppColors.grey500)),
                  items: vm.carCategoriesList.isEmpty 
                    ? [const DropdownMenuItem<String>(value: null, child: Text('Loading...', style: TextStyle(color: AppColors.grey500)))]
                    : vm.carCategoriesList.map((category) {
                        return DropdownMenuItem<String>(
                          value: category['_id'],
                          child: Text(category['name'], style: const TextStyle(color: AppColors.white), overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                  onChanged: (val) {
                    if (val != null) vm.setCarCategory(val);
                  },
                  dropdownColor: AppColors.grey900,
                  decoration: InputDecoration(
                    labelText: 'Type*',
                    labelStyle: const TextStyle(color: AppColors.grey500, fontSize: 14),
                    filled: true,
                    fillColor: AppColors.black,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.grey600, width: 1)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.yellow, width: 2)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _textField(
                label: 'Seats*', 
                hint: 'e.g., 4', 
                keyboardType: TextInputType.number, 
                // Using key to force rebuild when seatCapacity changes via dropdown
                key: ValueKey(vm.seatCapacity),
                initialValue: vm.seatCapacity, 
                onChanged: (v) => vm.seatCapacity = v,
                readOnly: true,
              ),
            ),
          ],
        ),
        _textField(label: 'Color*', hint: 'Car color', initialValue: vm.carColor, onChanged: (v) => vm.carColor = v),
        _textField(label: 'Mfg Year*', hint: 'e.g., 2020', keyboardType: TextInputType.number, initialValue: vm.manufacturingYear, onChanged: (v) => vm.manufacturingYear = v),
        const SizedBox(height: 16),
        const Text('Vehicle Documents', style: TextStyle(color: AppColors.grey500, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _imagePickerTile('RC Book Photo*', vm.rcImage, (source) => vm.pickImage('rcImage', source)),
        const SizedBox(height: 16),
        _dateField(context: context, label: 'Insurance Expiry*', hint: 'YYYY-MM-DD', initialValue: vm.insuranceExpiry, onChanged: (v) => vm.insuranceExpiry = v),
        _imagePickerTile('Insurance Paper Photo*', vm.insuranceImage, (source) => vm.pickImage('insuranceImage', source)),
        const SizedBox(height: 16),
        _dateField(context: context, label: 'Permit Expiry', hint: 'YYYY-MM-DD', initialValue: vm.permitExpiry, onChanged: (v) => vm.permitExpiry = v),
        _imagePickerTile('Permit Paper Photo', vm.permitImage, (source) => vm.pickImage('permitImage', source)),
        const SizedBox(height: 16),
        _dateField(context: context, label: 'PUC Expiry', hint: 'YYYY-MM-DD', initialValue: vm.pucExpiry, onChanged: (v) => vm.pucExpiry = v),
        _imagePickerTile('PUC Paper Photo', vm.pucImage, (source) => vm.pickImage('pucImage', source)),
      ],
    );
  }

  Widget _buildBankDetails(RegistrationViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bank Details', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _textField(label: 'Bank Name*', hint: 'e.g., HDFC Bank', initialValue: vm.bankName, onChanged: (v) => vm.bankName = v),
        _textField(label: 'Account Holder Name*', hint: 'As per bank records', initialValue: vm.accountHolderName, onChanged: (v) => vm.accountHolderName = v),
        _textField(label: 'Account Number*', hint: 'Enter account number', keyboardType: TextInputType.number, initialValue: vm.accountNumber, onChanged: (v) => vm.accountNumber = v),
        _textField(label: 'IFSC Code*', hint: 'Enter 11-digit IFSC', initialValue: vm.ifscCode, onChanged: (v) => vm.ifscCode = v),
      ],
    );
  }

  Widget _textField({
    Key? key,
    required String label,
    required String hint,
    required Function(String) onChanged,
    String initialValue = '',
    TextInputType? keyboardType,
    bool obscureText = false,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        key: key,
        initialValue: initialValue,
        onChanged: onChanged,
        keyboardType: keyboardType,
        obscureText: obscureText,
        readOnly: readOnly,
        style: TextStyle(color: readOnly ? AppColors.grey500 : AppColors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.grey500, fontSize: 14),
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.grey600.withOpacity(0.5), fontSize: 14),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          filled: true,
          fillColor: readOnly ? AppColors.grey900.withOpacity(0.5) : AppColors.black,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: readOnly ? AppColors.grey600.withOpacity(0.3) : AppColors.grey600, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: readOnly ? AppColors.grey600.withOpacity(0.3) : AppColors.yellow, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _dateField({
    required BuildContext context,
    required String label,
    required String hint,
    required Function(String) onChanged,
    String initialValue = '',
  }) {
    final TextEditingController controller = TextEditingController(text: initialValue);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.yellow,
                    onPrimary: AppColors.black,
                    surface: AppColors.grey900,
                    onSurface: AppColors.white,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (pickedDate != null) {
            String formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
            controller.text = formattedDate;
            onChanged(formattedDate);
          }
        },
        style: const TextStyle(color: AppColors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.grey500, fontSize: 14),
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.grey600.withOpacity(0.5), fontSize: 14),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          filled: true,
          fillColor: AppColors.black,
          suffixIcon: const Icon(Icons.calendar_today, color: AppColors.yellow, size: 20),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.grey600, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.yellow, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _imagePickerTile(String title, XFile? file, Function(ImageSource) onPick) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey600.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: file != null ? AppColors.yellow : AppColors.grey600),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius: BorderRadius.circular(8),
              image: file != null ? DecorationImage(image: FileImage(File(file.path)), fit: BoxFit.cover) : null,
            ),
            child: file == null ? const Icon(Icons.image_outlined, color: AppColors.grey500) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(file != null ? 'Image Selected' : 'No image chosen', style: TextStyle(color: file != null ? AppColors.yellow : AppColors.grey500, fontSize: 12)),
              ],
            ),
          ),
          PopupMenuButton<ImageSource>(
            icon: const Icon(Icons.upload_file_rounded, color: AppColors.white),
            color: const Color(0xFF2C2C2C),
            onSelected: onPick,
            itemBuilder: (context) => [
              const PopupMenuItem(value: ImageSource.camera, child: Row(children: [Icon(Icons.camera_alt, color: AppColors.white, size: 20), SizedBox(width: 8), Text('Camera', style: TextStyle(color: AppColors.white))])),
              const PopupMenuItem(value: ImageSource.gallery, child: Row(children: [Icon(Icons.photo_library, color: AppColors.white, size: 20), SizedBox(width: 8), Text('Gallery', style: TextStyle(color: AppColors.white))])),
            ],
          ),
        ],
      ),
    );
  }
}
