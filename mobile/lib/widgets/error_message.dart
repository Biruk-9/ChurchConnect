import 'package:flutter/material.dart';

class ErrorMessage extends StatelessWidget {
	final String message;
	final VoidCallback? onRetry;

	const ErrorMessage({super.key, required this.message, this.onRetry});

	@override
	Widget build(BuildContext context) {
		return Center(
			child: Column(
				mainAxisSize: MainAxisSize.min,
				children: [
					Text(
						message,
						textAlign: TextAlign.center,
						style: Theme.of(context)
								.textTheme
								.bodyMedium
								?.copyWith(color: Colors.redAccent),
					),
					if (onRetry != null) ...[
						const SizedBox(height: 12),
						OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
					],
				],
			),
		);
	}
}
