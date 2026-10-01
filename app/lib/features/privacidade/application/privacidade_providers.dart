import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../data/supabase_exclusao_conta_repository.dart';
import '../domain/exclusao_conta_repository.dart';

final exclusaoContaRepositoryProvider = Provider<ExclusaoContaRepository>(
  (ref) => SupabaseExclusaoContaRepository(),
);

/// Entrega um arquivo ao usuário pela folha de compartilhamento do sistema
/// (na web, baixa o arquivo). Injetável para os testes não abrirem plugins.
final compartilharArquivoProvider =
    Provider<Future<void> Function(Uint8List bytes, String nomeArquivo)>(
      (ref) =>
          (bytes, nomeArquivo) =>
              Printing.sharePdf(bytes: bytes, filename: nomeArquivo),
    );
