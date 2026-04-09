import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_route_path.dart';
import '../bloc/upload/upload_bloc.dart';

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0E8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Upload File',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: BlocConsumer<UploadBloc, UploadState>(
        listener: (context, state) {
          if (state is UploadSuccessState) {
            context.pushNamed(
              AppRoute.textPad.name,
              extra: {
                'text': state.document.text ?? '',
                'sourceName': state.document.sourceName,
              },
            );
          } else if (state is UploadFailureState) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          return Center(
            child: state is UploadLoadingState
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.upload_file_rounded,
                          size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Pick a file to extract text'),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.folder_open_rounded),
                        label: const Text('Choose File'),
                        onPressed: () => context
                            .read<UploadBloc>()
                            .add(PickAndExtractEvent()),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
