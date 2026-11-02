# Integração facial — entrega de 3 de novembro de 2026

## O que esta atualização conecta

O app Flutter envia a foto para `usuarios` no Firestore. O processo
`integracao_firebase.py`, aberto no computador, valida a foto, gera o embedding
real e devolve o resultado ao app. O processo `catraca_firebase.py` compara a
webcam com os cadastros prontos e registra a decisão em `acessos`.

Nesta entrega o processamento do cadastro fica no computador, aproveitando o
envio de fotos já implementado. É uma adaptação explícita da arquitetura inicial
que previa inferência no celular. Cadastro e reconhecimento usam a MESMA classe,
pesos e alinhamento. O app não gera embeddings nesta versão.

O resultado de acesso é uma **liberação simulada na tela**, sem mover servo.
Os scripts antigos `registro.py` e `destravamento.py` continuam sendo protótipos
com placeholder. **Não os use para demonstrar reconhecimento real.**

## 1. Aplicar a atualização

A atualização foi preparada sobre o commit `7ab4095` do repositório
`PUC-Minas-Embarcados-02-2026/Sistemas-embarcados`.

Baixe `integracao-facial.patch` e coloque-o na pasta `Sistemas-embarcados`,
ao lado das pastas `app-mobile`, `database` e `Reconhecimento_Facial0.3`.
Abra o terminal nessa pasta. No computador mostrado na conversa:

```powershell
cd "$env:USERPROFILE\Documents\Sistemas-embarcados"
git status
git apply --check .\integracao-facial.patch
```

Se a verificação terminar sem erro:

```powershell
git apply .\integracao-facial.patch
```

Se aparecer `patch does not apply` ou `already exists`, pare e confira as
alterações locais; não use comandos de descarte. O patch não foi enviado ao
GitHub automaticamente. As alterações aplicadas podem ser revisadas com
`git diff` e `git status`.

## 2. Preparar Python e modelo (uma vez)

Use **Python 3.12 ou 3.11, 64 bits** no Windows. Veja as versões instaladas:

```powershell
py -0p
```

Na raiz de `Sistemas-embarcados`:

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r .\Reconhecimento_Facial0.3\requirements-integracao.txt
.\.venv\Scripts\python.exe .\Reconhecimento_Facial0.3\baixar_modelo.py
```

Se tiver somente Python 3.11, troque apenas `py -3.12` por `py -3.11`.
Se não tiver nenhum dos dois, instale uma dessas versões pelo site oficial
https://www.python.org/downloads/windows/. Não é necessário instalar Android
Studio para executar esta parte. O ambiente virtual é usado pelo caminho
completo; não precisa ativá-lo nem alterar a política do PowerShell.

O modelo oficial é baixado do InsightFace e o SHA-256 do pacote é verificado.
O arquivo MediaPipe `face_landmarker.task` já está no repositório. Os caminhos
são relativos aos arquivos Python, então é possível executar da raiz.

## 3. Credencial do Firebase

O serviço precisa da credencial Firebase Admin do mesmo projeto configurado no
app. O projeto já prevê o arquivo:

```text
Sistemas-embarcados/database/firebase_credentials.json
```

Use a credencial local já usada pela integração do banco, ou peça ao responsável
pelo Firebase para configurá-la neste computador. Se precisar gerar uma, use
Firebase Console → Configurações do projeto → Contas de serviço → Gerar nova
chave privada. Se não tiver permissão, o responsável pelo projeto precisa fazer
essa etapa. Não substitua esse arquivo por `google-services.json`: são arquivos
com funções diferentes.

**Não envie a chave privada pelo chat nem ao GitHub.** O arquivo está no
`.gitignore`. Como alternativa, defina `GOOGLE_APPLICATION_CREDENTIALS` com o
caminho da chave no computador, em cada terminal dos serviços.

Nenhuma regra do Firestore foi alterada por esta atualização. O app precisa das
permissões de leitura e gravação do próprio cadastro; o serviço usa Admin SDK.
Não abra regras públicas para contornar `permission-denied`. A autenticação e as
regras definitivas continuam pendentes no projeto original; esta é uma demo
supervisionada, não um sistema de acesso pronto para produção.

## 4. Abrir o processador de cadastros

No primeiro terminal, na raiz do repositório:

```powershell
.\.venv\Scripts\python.exe .\Reconhecimento_Facial0.3\integracao_firebase.py
```

Deixe aberto. Deve aparecer:

```text
Integração ativa. Cadastre uma foto no app. Ctrl+C para encerrar.
```

Cadastros antigos com consentimento e foto também são processados. O serviço
não cria novas pessoas: atualiza o documento existente. Fotografias inválidas
ficam com `facialStatus: erro`; é preciso tirar outra foto pelo app.

## 5. Abrir o app e cadastrar

Em outro terminal:

```powershell
cd .\app-mobile
flutter pub get
flutter analyze
flutter devices
flutter run
```

Selecione o S20 FE quando ele aparecer autorizado. Para testar pelo navegador,
use `flutter run -d chrome`. Se usar a webcam do notebook no app, termine a
captura antes de abrir a catraca, para evitar disputa pela câmera.

Preencha nome, autorize o uso, tire uma foto frontal bem iluminada, sem máscara
e com apenas uma pessoa, e finalize. O app deve mostrar **Validando sua foto**
e depois **Rosto pronto**. Só então clique em **Continuar**.

Se esperar mais de 45 segundos, o app mostra uma orientação para conferir o
serviço e a internet; ele continua escutando e não declara sucesso sem resposta
confirmada do servidor. Uma foto nova invalida imediatamente o vetor anterior.

## 6. Abrir o reconhecimento pela webcam

Em um terceiro terminal, na raiz do repositório:

```powershell
.\.venv\Scripts\python.exe .\Reconhecimento_Facial0.3\catraca_firebase.py
```

Olhe para a webcam. Depois de três comparações consecutivas da mesma pessoa,
o sistema revalida o cadastro no Firebase, registra a decisão e mostra a
liberação simulada. O console mostra a decisão e a similaridade. O intervalo
entre registros é de oito segundos, para não gravar um acesso a cada frame.

Se a câmera não abrir, feche Teams, Meet, Zoom e outras abas usando a webcam.
Para outra câmera:

```powershell
.\.venv\Scripts\python.exe .\Reconhecimento_Facial0.3\catraca_firebase.py --camera 1
```

Pressione `Q` para encerrar a webcam. Use `Ctrl+C` no processador quando terminar.
Os aparelhos precisam de acesso à internet/Firebase; não é necessário configurar
IP do notebook, abrir porta HTTP ou estar na mesma rede local.

## 7. Roteiro de aceitação antes de apresentar

| Teste | Resultado esperado |
|---|---|
| Cadastro com uma foto válida pelo app | `facialStatus=pronto`, vetor de 512 números e tela Rosto pronto |
| Mesma pessoa, agora na webcam | Decisão autorizada em `acessos`, `metodo=facial`, `acionamentoFisico=false` |
| Outra pessoa não cadastrada | Acesso negado; nenhum anúncio de liberação |
| Foto sem rosto ou com duas pessoas | Erro no app e nenhum vetor válido para acesso |
| Nova foto no mesmo cadastro | Vetor anterior excluído; nova versão precisa ser processada |
| Dois cadastros da mesma pessoa | Pode rejeitar por ambiguidade; mantenha um cadastro por pessoa na demo |
| Serviço parado durante o cadastro | App permanece aguardando; não mostra conclusão falsa |
| Firebase indisponível durante uma decisão | Nenhum acesso liberado |

Faça o teste com pelo menos duas pessoas consentindo, variando levemente
iluminação e distância. Se o próprio rosto não reconhecer, examine o
enquadramento e refaça a foto antes de mudar o limiar. A similaridade **não é
uma porcentagem de confiança**. O padrão é `--limiar 0.60 --margem 0.08`, ainda
sem calibração com a câmera de vocês; registre os resultados de conhecidos e
desconhecidos antes de ajustar. Não reduza o limiar apenas para forçar aceitação.

## Validação feita no ambiente de desenvolvimento

- 21 testes automatizados aprovados: comparação, ambiguidade, alinhamento, consentimento,
  troca de modelo, atualização concorrente e invalidação de fotos.
- Execução real do ONNX em CPU: saída finita de 512 valores.
- Teste com duas imagens públicas de exemplo: alteração de iluminação da
  imagem cadastrada aceita (similaridade 0,9972); outra imagem rejeitada
  (similaridade -0,0006); imagem sem rosto e imagem com duas pessoas rejeitadas.
- Dependências Python verificadas com `pip check`.
- Sintaxe dos arquivos Dart alterados verificada pelo formatador Dart.
- `flutter analyze` não concluído neste ambiente: a revisão automática bloqueou
  uma tentativa da ferramenta de acessar metadados da infraestrutura. Execute
  a análise no computador da equipe antes de testar o app.

Esses testes não medem a acurácia em pessoas/câmeras da turma. A conexão com o
Firebase real, a execução Flutter no S20 FE e o vídeo da webcam precisam ser
verificados no computador da equipe. Nenhuma credencial foi usada nos testes.

Para repetir os testes de lógica:

```powershell
.\.venv\Scripts\python.exe -m pip install pytest
.\.venv\Scripts\python.exe -m pytest .\Reconhecimento_Facial0.3\tests -q
```

## Limites desta entrega

Não há prova de vida: uma fotografia apresentada à webcam pode ser aceita.
A detecção automática de acessórios do protótipo antigo é heurística e não foi
apresentada como uma validação confiável nesta integração. A verificação de
foto exige um único rosto detectável com tamanho suficiente.

O RFID existente não foi alterado. Servo, display e Raspberry Pi não foram
testados nesta entrega. A instalação aqui documentada é para notebook Windows;
o Pi pode precisar de versões de pacotes específicas para ARM.

## Modelo e referências

MediaPipe Face Landmarker + reconhecimento MBF/WebFace600K
`w600k_mbf.onnx`, do pacote oficial `buffalo_sc` (mesmo reconhecedor de
`buffalo_s`). O vetor é normalizado; a comparação é por cosseno. O identificador
armazenado cobre pesos ONNX, pesos MediaPipe e versão do alinhamento. Vetores
geométricos antigos não são utilizados.

- Modelos e condições de uso acadêmico/não comercial: https://github.com/deepinsight/insightface/tree/master/model_zoo
- Distribuição oficial: https://github.com/deepinsight/insightface/releases/tag/model-zoo
- Contrato de entrada ArcFace: https://github.com/deepinsight/insightface/blob/master/python-package/insightface/model_zoo/arcface_onnx.py
- Transações Firestore: https://firebase.google.com/docs/firestore/manage-data/transactions
