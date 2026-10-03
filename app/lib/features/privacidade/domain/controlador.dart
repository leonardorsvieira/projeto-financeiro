// Dados do controlador (LGPD art. 5º, VI) usados nos documentos legais.
//
// Este é o ÚNICO lugar com o nome, o e-mail de contato e a versão dos
// documentos: os textos de `textos_legais.dart` interpolam estas constantes.
// O controlador é identificado pelo CNPJ; a razão social é opcional e, quando
// preenchida, aparece antes do CNPJ.

/// Razão social de quem responde pelos dados (vazio: só o CNPJ aparece).
const nomeControlador = '';

/// CNPJ de quem responde pelos dados.
const cnpjControlador = '68.018.160/0001-00';

/// Como o controlador aparece nos documentos ("a empresa inscrita no CNPJ…"
/// ou "razão social, CNPJ …").
const identificacaoControlador = nomeControlador.length == 0
    ? 'a empresa inscrita no CNPJ $cnpjControlador'
    : '$nomeControlador, CNPJ $cnpjControlador';

/// Canal de atendimento ao titular sobre privacidade e dados pessoais.
const emailPrivacidade = 'leonardorodriguesv99@gmail.com';

/// Versão vigente da Política de Privacidade e dos Termos de Uso (data ISO).
/// Mudar este valor pede novo aceite de todas as contas.
const versaoDocumentos = '2026-10-04';
