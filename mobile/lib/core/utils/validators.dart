final RegExp _emailRegex = RegExp(
	r"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}",
	caseSensitive: false,
);

String? requiredField(String? value, {String fieldName = 'This field'}) {
	if (value == null || value.trim().isEmpty) {
		return '$fieldName is required';
	}
	return null;
}

String? emailValidator(String? value) {
	if (value == null || value.trim().isEmpty) return 'Email is required';
	if (!_emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
	return null;
}

String? minLength(String? value, int length, {String fieldName = 'Field'}) {
	if (value == null || value.length < length) {
		return '$fieldName must be at least $length characters';
	}
	return null;
}
