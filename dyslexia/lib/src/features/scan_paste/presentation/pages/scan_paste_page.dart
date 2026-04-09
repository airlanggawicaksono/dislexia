import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_route_path.dart';
import '../bloc/scan/scan_bloc.dart';

class ScanPastePage extends StatefulWidget {
  const ScanPastePage({super.key});

  @override
  State<ScanPastePage> createState() => _ScanPastePageState();
}

class _ScanPastePageState extends State<ScanPastePage> {
  @override
  void initState() {
    super.initState();
    context.read<ScanBloc>().add(StartScanEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<ScanBloc, ScanState>(
        listener: (context, state) {
          if (state is ScanSuccessState) {
            context.pushReplacementNamed(
              AppRoute.textPad.name,
              extra: {
                'text': state.document.text ?? '',
                'sourceName': state.document.sourceName,
              },
            );
          } else if (state is ScanFailureState) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
            context.pop();
          }
        },
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Scanning document...'),
            ],
          ),
        ),
      ),
    );
  }
}
