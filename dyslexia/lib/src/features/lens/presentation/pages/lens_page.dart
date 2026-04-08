import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_route_path.dart';
import '../bloc/lens/lens_bloc.dart';

class LensPage extends StatelessWidget {
  const LensPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lens')),
      body: BlocConsumer<LensBloc, LensState>(
        listener: (context, state) {
          if (state is LensSuccessState) {
            context.pushNamed(
              AppRoute.textPad.name,
              extra: {
                'text': state.document.text ?? '',
                'sourceName': state.document.sourceName,
              },
            );
          } else if (state is LensFailureState) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          return state is LensLoadingState
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Capturing text...'),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    // TODO: Replace with CameraPreview(controller) once camera package is added
                    Container(
                      color: Colors.black,
                      child: const Center(
                        child: Text(
                          'Camera Preview',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: FloatingActionButton.extended(
                          icon: const Icon(Icons.center_focus_strong_rounded),
                          label: const Text('Capture Text'),
                          onPressed: () =>
                              context.read<LensBloc>().add(CaptureTextEvent()),
                        ),
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }
}
