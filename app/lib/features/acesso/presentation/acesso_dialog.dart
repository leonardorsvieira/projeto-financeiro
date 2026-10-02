import 'package:flutter/material.dart';

import '../../../theme/icones.dart';
import '../domain/acesso.dart';
import '../domain/regras_acesso.dart';

/// Dados confirmados no diálogo de acesso.
typedef DadosAcesso = ({String email, DateTime? validoAte, String? observacao});

/// Diálogo para criar ([existente] nulo) ou editar um acesso. O e-mail é a
/// chave da linha, então não muda na edição. Devolve null se cancelado.
Future<DadosAcesso?> mostrarDialogoAcesso(
  BuildContext context, {
  Acesso? existente,
  required DateTime hoje,
}) {
  return showDialog<DadosAcesso>(
    context: context,
    builder: (_) => _DialogoAcesso(existente: existente, hoje: hoje),
  );
}

class _DialogoAcesso extends StatefulWidget {
  const _DialogoAcesso({required this.existente, required this.hoje});

  final Acesso? existente;
  final DateTime hoje;

  @override
  State<_DialogoAcesso> createState() => _DialogoAcessoState();
}

class _DialogoAcessoState extends State<_DialogoAcesso> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email = TextEditingController(
    text: widget.existente?.email,
  );
  late final TextEditingController _observacao = TextEditingController(
    text: widget.existente?.observacao,
  );
  late bool _semPrazo =
      widget.existente != null && widget.existente!.validoAte == null;
  late DateTime _validade =
      widget.existente?.validoAte ?? novaValidade(null, widget.hoje);

  bool get _editando => widget.existente != null;

  @override
  void dispose() {
    _email.dispose();
    _observacao.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final hoje = soData(widget.hoje);
    final primeira = DateTime(hoje.year, hoje.month, hoje.day - 365);
    final ultima = DateTime(hoje.year, hoje.month, hoje.day + 3650);
    final inicial = _validade.isBefore(primeira)
        ? primeira
        : (_validade.isAfter(ultima) ? ultima : _validade);
    final escolhida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: primeira,
      lastDate: ultima,
    );
    if (escolhida != null && mounted) {
      setState(() => _validade = soData(escolhida));
    }
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    final obs = _observacao.text.trim();
    Navigator.of(context).pop((
      email: normalizarEmail(_email.text),
      validoAte: _semPrazo ? null : _validade,
      observacao: obs.isEmpty ? null : obs,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editando ? 'Editar acesso' : 'Novo acesso'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _email,
                  readOnly: _editando,
                  autofocus: !_editando,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: (v) {
                    final email = normalizarEmail(v ?? '');
                    if (email.isEmpty) return 'Informe o e-mail.';
                    if (!emailValido(email)) return 'Informe um e-mail válido.';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sem prazo'),
                  value: _semPrazo,
                  onChanged: (v) => setState(() => _semPrazo = v),
                ),
                if (!_semPrazo)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const PhosphorIcon(Icones.data),
                    title: const Text('Válido até'),
                    subtitle: Text(formatarData(_validade)),
                    onTap: _escolherData,
                  ),
                TextFormField(
                  controller: _observacao,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Observação (opcional)',
                    hintText: 'Ex.: Pix de outubro',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }
}
