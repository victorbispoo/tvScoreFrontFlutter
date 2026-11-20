import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../models/content_metadata.dart';
import '../services/api_services.dart';
import 'details_page.dart';

class DetailsRoutePage extends StatefulWidget {
  const DetailsRoutePage({super.key, required this.id, required this.type});

  final int id;
  final String type;

  @override
  State<DetailsRoutePage> createState() => _DetailsRoutePageState();
}

class _DetailsRoutePageState extends State<DetailsRoutePage> {
  late Future<Map<String, String>> _content = _load();

  Future<Map<String, String>> _load() async {
    final content = await ApiService().getContent(widget.id, widget.type);
    if (content.contentKey != (widget.id.toString(), widget.type)) {
      throw const FormatException('A resposta não corresponde ao título.');
    }
    return content;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, String>>(
    future: _content,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Carregando detalhes',
            ),
          ),
        );
      }
      if (snapshot.hasData) {
        return DetailsPage(content: snapshot.data!, contentLoaded: true);
      }
      final error = snapshot.error;
      if (error is DioException && error.response?.statusCode == 404) {
        return const DetailsRouteError(message: 'Conteúdo não encontrado.');
      }
      return DetailsRouteError(
        message: 'Não foi possível carregar os detalhes.',
        onRetry: () => setState(() {
          _content = _load();
        }),
      );
    },
  );
}

class DetailsRouteError extends StatelessWidget {
  const DetailsRouteError({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              if (onRetry != null)
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Tentar novamente'),
                ),
              TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
                child: const Text('Voltar ao catálogo'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
