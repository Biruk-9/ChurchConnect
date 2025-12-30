import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
	final String label;
	final VoidCallback? onPressed;
	final bool loading;
	final bool expanded;

	const CustomButton({
		super.key,
		required this.label,
		this.onPressed,
		this.loading = false,
		this.expanded = true,
	});

	@override
	Widget build(BuildContext context) {
		final btn = ElevatedButton(
			onPressed: loading ? null : onPressed,
			child: loading
					? const SizedBox(
							width: 18,
							height: 18,
							child: CircularProgressIndicator(strokeWidth: 2),
						)
					: Text(label),
		);

		if (expanded) {
			return SizedBox(width: double.infinity, child: btn);
		}
		return btn;
	}
}
