import 'controlador.dart';
import 'documento_legal.dart';

/// Frases curtas em destaque (LGPD art. 33, VIII): mostradas no cadastro e na
/// tela de re-aceite, ao lado do aceite dos documentos.
const List<String> destaquesPrivacidade = [
  'O ditado e as análises por IA são processados pelo Google (Gemini), '
      'fora do Brasil. No plano gratuito, o Google pode usar o conteúdo para '
      'melhorar seus serviços.',
  'O Open Finance é opcional e só funciona com a sua autorização no '
      'próprio banco.',
  'Você pode exportar seus dados ou excluir a conta a qualquer momento em '
      'Privacidade e dados.',
];

/// Política de Privacidade (LGPD art. 9). Os textos descrevem os fluxos reais
/// do app: se o código mudar (provedor, dado coletado), mude aqui e suba
/// `versaoDocumentos`.
const DocumentoLegal politicaDePrivacidade = DocumentoLegal(
  titulo: 'Política de Privacidade',
  versao: versaoDocumentos,
  introducao:
      'Esta política explica, em linguagem simples, quais dados o Meu Bolso '
      'trata, para que, com quem os compartilha e como você exerce os '
      'direitos que a Lei Geral de Proteção de Dados (LGPD, Lei nº '
      '13.709/2018) garante.',
  secoes: [
    SecaoLegal(
      titulo: '1. Quem cuida dos seus dados',
      blocos: [
        ParagrafoLegal(
          'O controlador dos seus dados pessoais, responsável pelo Meu '
          'Bolso, é $identificacaoControlador.',
        ),
        ParagrafoLegal(
          'Para qualquer assunto sobre seus dados, escreva para '
          '$emailPrivacidade. Esse é o canal de atendimento ao titular: a '
          'mensagem chega direto ao responsável.',
        ),
      ],
    ),
    SecaoLegal(
      titulo: '2. Quais dados tratamos',
      blocos: [
        ParagrafoLegal(
          'Cadastro: seu e-mail; sua senha, que o Supabase Auth guarda só '
          'como hash (ninguém consegue lê-la); seu nome, se você o informar; '
          'e o registro do aceite destes documentos, com versão e data.',
        ),
        ParagrafoLegal(
          'Dados financeiros que você registra: lançamentos, com descrição, '
          'valor, data, categoria, forma de pagamento, vencimento, itens e '
          'recorrência, e metas de gasto.',
        ),
        ParagrafoLegal(
          'Ditado por voz: o áudio é gravado num arquivo temporário do '
          'aparelho, substituído a cada novo ditado, e enviado pelo servidor '
          'do app ao Google Gemini só para transcrever e classificar. O '
          'servidor do app não armazena o áudio nem a transcrição. Fica salvo '
          'apenas o lançamento que você revisar e confirmar.',
        ),
        ParagrafoLegal(
          'Análise do mês e Guia de investimentos, só quando você toca no '
          'botão: o servidor do app envia ao Google Gemini totais e médias — '
          'receitas, despesas, despesas por categoria, saldo das contas, '
          'faturas em aberto e seus investimentos (nome, classe, valor e '
          'rendimento) —, além do perfil e da observação que você escrever '
          'no guia. Descrições de lançamentos não são enviadas. O guia usa a '
          'Busca Google para consultar dados de mercado. O servidor do app '
          'não armazena a resposta.',
        ),
        ParagrafoLegal(
          'Open Finance, se você conectar um banco: por meio da Pluggy, o '
          'app recebe contas e cartões, transações e investimentos que você '
          'autorizar. A conexão exige o seu consentimento na própria '
          'instituição, e suas credenciais bancárias são digitadas no '
          'ambiente da instituição ou da Pluggy, sem passar pelo app. O '
          'servidor guarda o identificador de cada conexão para que só você '
          'a acesse. As transações importadas entram no seu livro-caixa e os '
          'investimentos ficam espelhados no servidor.',
        ),
        ParagrafoLegal(
          'Dados que ficam só no aparelho: cartões de crédito cadastrados, '
          'contas conectadas (apenas nome e identificação, sem credenciais), '
          'preferências de lembrete, tema, configuração de biometria, '
          'notificações agendadas e o widget da tela inicial. Esses dados não '
          'são sincronizados e são apagados quando você sai da conta.',
        ),
        ParagrafoLegal(
          'Biometria: a verificação é feita pelo sistema Android ou iOS. O '
          'app recebe apenas a resposta "liberado" ou "não liberado", nunca a '
          'sua digital ou o seu rosto.',
        ),
        ParagrafoLegal(
          'Registros técnicos: a contagem diária de uso do ditado e do Open '
          'Finance, para aplicar limites e prevenir abuso, e os registros de '
          'acesso mantidos pelo provedor de autenticação (data, hora e '
          'endereço IP do login).',
        ),
      ],
    ),
    SecaoLegal(
      titulo: '3. Para que usamos seus dados',
      blocos: [
        ListaLegal([
          'prestar o serviço: guardar e organizar seus lançamentos, mostrar '
              'o resumo do mês, as metas e os lembretes;',
          'transcrever e classificar o que você dita;',
          'importar os dados do Open Finance que você autorizar;',
          'manter a segurança, aplicar limites de uso e prevenir abuso;',
          'enviar os e-mails da conta, como confirmação de cadastro e '
              'redefinição de senha;',
          'cumprir obrigações legais.',
        ]),
        ParagrafoLegal(
          'A classificação feita pela inteligência artificial é uma sugestão '
          'que você confere antes de salvar. Não há decisão automatizada que '
          'afete seus interesses.',
        ),
        ParagrafoLegal(
          'Não usamos seus dados para publicidade e não os vendemos.',
        ),
      ],
    ),
    SecaoLegal(
      titulo: '4. Bases legais (LGPD, art. 7º)',
      blocos: [
        ListaLegal([
          'Execução de contrato (art. 7º, V): para manter a conta e prestar '
              'o serviço.',
          'Consentimento (art. 7º, I): para o Open Finance e para o ditado '
              'por voz. Você pode revogá-lo a qualquer momento, desconectando '
              'o banco em "Bancos e Open Finance" ou deixando de usar o '
              'ditado.',
          'Legítimo interesse (art. 7º, IX): para segurança e prevenção de '
              'abuso.',
          'Cumprimento de obrigação legal (art. 7º, II): para a guarda dos '
              'registros de acesso, conforme o Marco Civil da Internet '
              '(Lei nº 12.965/2014, art. 15).',
        ]),
      ],
    ),
    SecaoLegal(
      titulo: '5. Com quem compartilhamos',
      blocos: [
        ListaLegal([
          'Supabase: banco de dados, autenticação e funções do servidor. Os '
              'dados ficam armazenados em São Paulo, Brasil.',
          'Google (API Gemini): recebe o áudio do ditado e as instruções de '
              'classificação e, quando você pede a análise do mês ou o guia '
              'de investimentos, os totais descritos acima.',
          'Pluggy: serviço de Open Finance, empresa brasileira, usado só se '
              'você conectar um banco.',
          'Autoridades, quando a lei exigir.',
        ]),
        ParagrafoLegal(
          'Atenção ao plano gratuito do Gemini. O Meu Bolso usa o plano '
          'gratuito da API Gemini. Pelos termos do Google para esse plano, o '
          'Google pode usar o conteúdo enviado e as respostas para melhorar '
          'seus produtos e serviços, inclusive com revisão humana. Por isso, '
          'dite só o necessário para o lançamento e evite informações '
          'sensíveis, como senhas, número completo de cartão e dados de '
          'saúde — inclusive na observação do guia de investimentos.',
        ),
      ],
    ),
    SecaoLegal(
      titulo: '6. Transferência internacional (art. 33)',
      blocos: [
        ParagrafoLegal(
          'O ditado, a análise do mês e o guia de investimentos são '
          'processados pelo Google nos Estados Unidos e em outros países. A '
          'base é o seu consentimento específico e em destaque (art. 33, '
          'VIII), dado ao aceitar estes documentos e ao usar esses recursos.',
        ),
        ParagrafoLegal(
          'Os demais provedores também podem trafegar dados por outros '
          'países, sempre com conexão criptografada (HTTPS).',
        ),
      ],
    ),
    SecaoLegal(
      titulo: '7. Por quanto tempo guardamos',
      blocos: [
        ListaLegal([
          'Enquanto a conta existir. O lançamento que você exclui sai do '
              'banco.',
          'Ao excluir a conta, os dados do servidor são apagados e as '
              'conexões bancárias são desfeitas na Pluggy.',
          'Cópias de segurança do provedor podem manter dados por um período '
              'limitado, até serem substituídas.',
          'Os registros de acesso podem ser mantidos pelo prazo legal de 6 '
              'meses (Marco Civil da Internet, art. 15), mesmo depois da '
              'exclusão da conta.',
          'Os dados do aparelho são apagados quando você sai ou exclui a '
              'conta.',
        ]),
      ],
    ),
    SecaoLegal(
      titulo: '8. Seus direitos (art. 18)',
      blocos: [
        ParagrafoLegal('Você pode pedir, a qualquer momento:'),
        ListaLegal([
          'confirmação de que tratamos seus dados e acesso a eles;',
          'correção de dados incompletos, inexatos ou desatualizados;',
          'anonimização, bloqueio ou eliminação de dados desnecessários;',
          'portabilidade dos dados;',
          'eliminação dos dados tratados com o seu consentimento;',
          'informação sobre com quem compartilhamos seus dados;',
          'informação sobre a possibilidade de não consentir e sobre as '
              'consequências da recusa;',
          'revogação do consentimento;',
          'oposição a um tratamento feito sem o seu consentimento, quando '
              'houver descumprimento da lei;',
          'revisão de decisões tomadas unicamente de forma automatizada.',
        ]),
        ParagrafoLegal(
          'Como exercer: no app, em "Privacidade e dados" (exportar seus '
          'dados em CSV e excluir a conta), editando ou excluindo '
          'lançamentos e desconectando bancos. Ou escreva para '
          '$emailPrivacidade. Respondemos em até 15 dias.',
        ),
        ParagrafoLegal(
          'Você também pode reclamar à Autoridade Nacional de Proteção de '
          'Dados (ANPD).',
        ),
      ],
    ),
    SecaoLegal(
      titulo: '9. Segurança',
      blocos: [
        ListaLegal([
          'os dados de cada pessoa ficam isolados no banco: cada conta só '
              'acessa os próprios dados;',
          'as chaves dos serviços ficam só no servidor, nunca no app;',
          'as conexões usam HTTPS;',
          'a senha é guardada como hash;',
          'o bloqueio por biometria é opcional;',
          'os dados do aparelho são limpos quando você sai da conta.',
        ]),
        ParagrafoLegal(
          'Se houver um incidente com risco relevante para você, avisaremos '
          'você e a ANPD (art. 48). Nenhum sistema é infalível: use uma '
          'senha forte e não a compartilhe.',
        ),
      ],
    ),
    SecaoLegal(
      titulo: '10. Crianças e adolescentes',
      blocos: [
        ParagrafoLegal('O Meu Bolso não se destina a menores de 18 anos.'),
      ],
    ),
    SecaoLegal(
      titulo: '11. Alterações desta política',
      blocos: [
        ParagrafoLegal(
          'Quando houver uma nova versão, avisamos no app e pedimos um novo '
          'aceite. A versão vigente aparece no topo deste documento.',
        ),
      ],
    ),
    SecaoLegal(
      titulo: '12. Contato',
      blocos: [
        ParagrafoLegal('Dúvidas ou pedidos sobre seus dados: '
            '$emailPrivacidade.'),
      ],
    ),
  ],
);

/// Termos de Uso. Sem cláusula de isenção total: os direitos do consumidor
/// (CDC) são preservados e o foro é o do domicílio do consumidor.
const DocumentoLegal termosDeUso = DocumentoLegal(
  titulo: 'Termos de Uso',
  versao: versaoDocumentos,
  introducao:
      'Estes Termos de Uso regem o uso do Meu Bolso. Leia com calma: eles '
      'dizem o que o app faz, o que esperamos de você e o que você pode '
      'esperar de nós.',
  secoes: [
    SecaoLegal(
      titulo: '1. Aceitação',
      blocos: [
        ParagrafoLegal(
          'Ao criar a conta, ou ao aceitar estes Termos no app, você '
          'concorda com eles e com a Política de Privacidade. Quem não '
          'concordar não deve usar o app.',
        ),
      ],
    ),
    SecaoLegal(
      titulo: '2. O que é o Meu Bolso',
      blocos: [
        ParagrafoLegal(
          'O Meu Bolso é um aplicativo de organização financeira pessoal: '
          'lançamentos por voz ou manuais, lembretes de vencimento, resumo '
          'do mês, metas e, se você quiser, Open Finance. O fornecedor é '
          '$identificacaoControlador.',
        ),
      ],
    ),
    SecaoLegal(
      titulo: '3. Sua conta',
      blocos: [
        ListaLegal([
          'Você declara ter 18 anos ou mais.',
          'Os dados que você informa devem ser verdadeiros.',
          'A senha é pessoal e fica sob a sua guarda.',
          'Se suspeitar de acesso indevido à sua conta, avise pelo e-mail '
              '$emailPrivacidade.',
        ]),
      ],
    ),
    SecaoLegal(
      titulo: '4. Ditado e inteligência artificial',
      blocos: [
        ParagrafoLegal(
          'A inteligência artificial pode errar o valor, a categoria ou a '
          'data. Por isso, você revisa o rascunho antes de salvar, e o que '
          'você confirma passa a ser um registro seu.',
        ),
        ParagrafoLegal(
          'A análise do mês e o guia de investimentos são textos gerados por '
          'IA a partir dos seus números e de pesquisas na internet: podem '
          'conter erros ou dados desatualizados. Confira antes de decidir.',
        ),
        ParagrafoLegal(
          'Podem ser aplicados limites diários de uso do ditado, da análise '
          'e do guia.',
        ),
      ],
    ),
    SecaoLegal(
      titulo: '5. Não é consultoria',
      blocos: [
        ParagrafoLegal(
          'O Meu Bolso oferece informação para organizar suas finanças. Ele '
          'não é consultoria financeira, de investimentos, contábil ou '
          'tributária. As decisões são suas.',
        ),
        ParagrafoLegal(
          'O Guia de investimentos é conteúdo educativo: explica classes de '
          'investimento, critérios de escolha e o cenário de mercado, mas não '
          'recomenda comprar, vender ou manter nenhum ativo e não substitui '
          'um profissional certificado.',
        ),
      ],
    ),
    SecaoLegal(
      titulo: '6. Open Finance',
      blocos: [
        ParagrafoLegal(
          'O Open Finance é opcional, funciona por meio da Pluggy e exige a '
          'sua autorização na instituição financeira. Você pode revogá-la '
          'quando quiser.',
        ),
        ParagrafoLegal(
          'Os dados dependem das instituições e podem chegar com atraso ou '
          'com diferenças. Confira sempre no extrato oficial.',
        ),
      ],
    ),
    SecaoLegal(
      titulo: '7. Serviços de terceiros e disponibilidade',
      blocos: [
        ParagrafoLegal(
          'O app depende de serviços de terceiros, como Supabase, Google, '
          'Pluggy e os bancos. Pode haver indisponibilidade ou manutenção. '
          'Trabalhamos para restabelecer o serviço o mais rápido possível.',
        ),
      ],
    ),
    SecaoLegal(
      titulo: '8. Responsabilidades',
      blocos: [
        ParagrafoLegal(
          'Respondemos por falhas do serviço nos termos do Código de Defesa '
          'do Consumidor.',
        ),
        ParagrafoLegal(
          'Não respondemos nas hipóteses que a lei exclui, como a culpa '
          'exclusiva do usuário ou de terceiro (Código de Defesa do '
          'Consumidor, art. 14, § 3º). Por exemplo: um lançamento confirmado '
          'com erro, uma decisão financeira tomada com base no app ou uma '
          'senha compartilhada pelo usuário.',
        ),
        ParagrafoLegal(
          'Nada nestes Termos afasta ou limita direitos que o Código de '
          'Defesa do Consumidor garante a você.',
        ),
      ],
    ),
    SecaoLegal(
      titulo: '9. Licença de uso do aplicativo',
      blocos: [
        ParagrafoLegal(
          'Você recebe uma licença pessoal, não exclusiva, intransferível e '
          'revogável para instalar o app em aparelhos seus. Não é permitido:',
        ),
        ListaLegal([
          'revender ou redistribuir o app;',
          'descompilar o app ou fazer engenharia reversa, salvo quando a lei '
              'permitir;',
          'contornar limites de uso ou mecanismos de segurança;',
          'tentar acessar dados de outras pessoas.',
        ]),
        ParagrafoLegal(
          'Quem adquiriu a licença pela internet ou fora de estabelecimento '
          'comercial pode desistir em até 7 dias (Código de Defesa do '
          'Consumidor, art. 49).',
        ),
      ],
    ),
    SecaoLegal(
      titulo: '10. Encerramento',
      blocos: [
        ParagrafoLegal(
          'Você exclui a sua conta quando quiser, em "Privacidade e dados". '
          'Contas que violem estes Termos ou a lei podem ser suspensas, com '
          'aviso quando possível. Os dados são tratados conforme a Política '
          'de Privacidade.',
        ),
      ],
    ),
    SecaoLegal(
      titulo: '11. Alterações',
      blocos: [
        ParagrafoLegal(
          'Quando estes Termos mudarem, avisamos no app e pedimos um novo '
          'aceite. Se você não concordar com a nova versão, pode excluir a '
          'conta.',
        ),
      ],
    ),
    SecaoLegal(
      titulo: '12. Lei e foro',
      blocos: [
        ParagrafoLegal(
          'Valem as leis brasileiras. O foro é o do domicílio do consumidor.',
        ),
      ],
    ),
    SecaoLegal(
      titulo: '13. Contato',
      blocos: [
        ParagrafoLegal('Dúvidas sobre estes Termos: $emailPrivacidade.'),
      ],
    ),
  ],
);
