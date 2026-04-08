import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_route_path.dart';
import '../bloc/scan/scan_bloc.dart';

class ScanPastePage extends StatelessWidget {
  const ScanPastePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan & Paste')),
      body: BlocConsumer<ScanBloc, ScanState>(
        listener: (context, state) {
          if (state is ScanSuccessState) {
            context.pushNamed(
              AppRoute.textPad.name,
              extra: {
                'text': state.document.text ?? '',
                'sourceName': state.document.sourceName,
              },
            );
          } else if (state is ScanFailureState) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          return Center(
            child: state is ScanLoadingState
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Reading text...'),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.document_scanner_rounded,
                          size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Point camera at text and scan'),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text('Scan'),
                        onPressed: () =>
                            context.read<ScanBloc>().add(StartScanEvent()),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
