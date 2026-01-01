import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
	final String label;
	final VoidCallback? onPressed;
	final bool loading;
	final bool expanded;
	final Color? backgroundColor;
	final Color? foregroundColor;
	final double? elevation;

	const CustomButton({
		super.key,
		required this.label,
		this.onPressed,
		this.loading = false,
		this.expanded = true,
		this.backgroundColor,
		this.foregroundColor,
		this.elevation,
	});

	@override
	Widget build(BuildContext context) {
		final btn = ElevatedButton(
			style: ElevatedButton.styleFrom(
				backgroundColor: backgroundColor,
				foregroundColor: foregroundColor,
				elevation: elevation,
			),
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
