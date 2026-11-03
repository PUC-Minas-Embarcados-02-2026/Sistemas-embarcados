# PUC Access — login real no celular

Atualização preparada em 3 de novembro de 2026, sobre o commit `caea87df1632d73a6f93e0b20f4132a163bbc50d` do repositório `PUC-Minas-Embarcados-02-2026/Sistemas-embarcados`.

O aplicativo passa a usar Firebase Authentication para criar uma conta, entrar com e-mail e senha, recuperar a senha e sair. O cadastro facial usa o UID dessa conta em `usuarios/{uid}`. A sessão restaurada pelo Firebase abre o cadastro da mesma pessoa. Sair descarta também as telas de câmera, validação e conclusão.

A conta é do **PUC Access**. Esta atualização não valida vínculo com a universidade e não usa a senha dos sistemas acadêmicos da PUC.

## 1. Habilitar e-mail e senha no Firebase — uma vez

1. Abra https://console.firebase.google.com/project/pucacess/authentication/providers.
2. Confira que selecionou o projeto **pucacess**, o mesmo do aplicativo.
3. Em **Authentication**, clique em **Começar**, se aparecer.
4. Abra **Método de login / Sign-in method** → **E-mail/senha**.
5. Habilite a opção **E-mail/senha** e salve. Não é necessário habilitar login por link de e-mail.

Não coloque a chave privada do Firebase Admin no aplicativo. O arquivo `database/firebase_credentials.json` continua sendo usado apenas pelos serviços Python no computador.

## 2. Aplicar a atualização — uma vez

Extraia `login-real.patch` do ZIP para:

```text
C:\Users\julia\Documents\PUC-Access-atualizado
```

Se o Flutter estiver rodando em um terminal, encerre somente aquela execução com **Ctrl+C**. Abra um terminal PowerShell no VS Code e cole o bloco completo:

```powershell
cd "$env:USERPROFILE\Documents\PUC-Access-atualizado"
git status --short
git apply --check .\login-real.patch
if ($LASTEXITCODE -ne 0) { throw "O patch não confere com seus arquivos. Pare aqui e envie a mensagem; não descarte suas alterações." }
git apply .\login-real.patch
if ($LASTEXITCODE -ne 0) { throw "Não foi possível aplicar a atualização. Pare aqui." }
```

A verificação não altera arquivos. Se houver `patch does not apply`, `already exists` ou qualquer erro, pare e envie a saída para ajustar a atualização à sua cópia. Não use `git reset --hard`, `git clean` nem sobrescreva seus arquivos para forçar a aplicação. Se o patch já estiver aplicado, não o aplique novamente.

O pacote não contém nem substitui sua credencial Firebase, ambiente Python ou modelos faciais. Também não envia alterações ao GitHub automaticamente.

## 3. Aplicar as regras do banco — uma vez

O login não substitui as regras do Firestore. A proteção entre contas depende desta etapa.

1. No VS Code, abra o arquivo **firestore.rules** que apareceu na raiz do projeto.
2. No Firebase, abra **Firestore Database → Regras / Rules**.
3. Guarde uma cópia das regras atualmente publicadas.
4. Para o banco usado por este repositório, copie o conteúdo de `firestore.rules` para o editor e publique.

Se o mesmo banco também atende outros aplicativos, o responsável deve integrar as regras necessárias deles antes de publicar. O arquivo fornecido bloqueia os clientes nas demais coleções; os serviços Python deste projeto usam Firebase Admin e continuam acessando os dados.

Não mantenha uma regra ampla como `allow read, write: if true` junto às novas regras: ela permitiria contornar a proteção. As regras fornecidas permitem que cada conta leia apenas seu próprio documento e envie uma foto **pendente**. A aprovação e o vetor facial continuam sendo gravados somente pelo serviço Python/Admin. Campos administrativos existentes, como RFID, são preservados e não podem ser alterados pelo aplicativo.

## 4. Instalar dependências e abrir no celular

No terminal do aplicativo:

```powershell
cd "$env:USERPROFILE\Documents\PUC-Access-atualizado\app-mobile"
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "Corrija o erro de dependências antes de continuar." }
flutter devices
flutter run -d RXCX209YHWD
```

O identificador acima é o do Samsung que apareceu no seu terminal. Se `flutter devices` mostrar outro, substitua o identificador no último comando. Deixe o telefone conectado e autorize a depuração USB se ele pedir.

É necessário iniciar uma nova execução do aplicativo, porque `firebase_auth` é um novo plugin. Hot reload sozinho não instala esse plugin.

Em **outro terminal**, mantenha o serviço de validação facial aberto:

```powershell
cd "$env:USERPROFILE\Documents\PUC-Access-atualizado\app-mobile"
.\.venv\Scripts\python.exe ..\Reconhecimento_Facial0.3\integracao_firebase.py
```

Não é preciso reinstalar Python, recriar o ambiente virtual nem baixar o modelo de novo. O login funciona independentemente desse serviço; a validação da foto precisa dele.

Para testar também a demonstração de reconhecimento pela webcam, use um terceiro terminal:

```powershell
cd "$env:USERPROFILE\Documents\PUC-Access-atualizado\app-mobile"
.\.venv\Scripts\python.exe ..\Reconhecimento_Facial0.3\catraca_firebase.py
```

## 5. Testar o login real

1. No celular, toque em **Criar uma conta**.
2. Informe um e-mail ao qual você tem acesso, crie uma senha e confirme. A política configurada no Firebase também será aplicada; o aplicativo exige pelo menos seis caracteres ao criar.
3. A conta deve aparecer em **Firebase → Authentication → Usuários**.
4. Complete o nome, autorize a foto e conclua o cadastro facial com o serviço Python aberto.
5. Toque em **Sair da conta**. O botão de voltar não deve reabrir telas privadas.
6. Tente entrar com uma senha incorreta: o aplicativo deve permanecer no login e mostrar a mensagem de erro.
7. Entre com a senha correta: o mesmo nome e foto devem ser carregados. Atualizar o cadastro usa o mesmo UID, sem criar outro documento para essa conta.
8. Feche e abra o aplicativo enquanto estiver conectado: a sessão deve ser restaurada.
9. Saia, preencha só o e-mail e toque em **Esqueci minha senha**. Confira a caixa de entrada e o spam. A mensagem do aplicativo é genérica para não revelar se o endereço possui uma conta.
10. Se testar uma segunda conta, ela deve abrir seu próprio cadastro.

## Cadastros antigos

Os registros anteriores foram criados sem uma conta autenticada e podem ter IDs aleatórios. Eles não são associados automaticamente pelo nome ou pelo rosto.

Na primeira entrada com a nova conta, faça um cadastro facial vinculado a ela. Os registros antigos permanecem intactos. Se a mesma pessoa ficar cadastrada duas vezes, o reconhecimento pode considerar o resultado ambíguo: o responsável deve revisar os registros antigos e decidir sua migração ou desativação, preservando o histórico e o vínculo RFID. Nada é excluído por esta atualização.

Os serviços Dart antigos, sem uso no aplicativo, foram removidos: um deles gravava uma senha em texto puro na coleção `usuario`. Esta atualização não usa essa coleção nem migra aquelas senhas. Contas antigas precisam ser criadas no Authentication; senhas nunca são copiadas para o Firestore.

## Se aparecer um erro

| Situação | O que conferir |
| --- | --- |
| “O login por e-mail ainda não foi habilitado” | Etapa 1, no projeto `pucacess`. |
| “Este e-mail já tem uma conta” | Use **Entrar** ou **Esqueci minha senha**. |
| Entrou, mas não carregou/salvou o cadastro | Internet e regras publicadas na etapa 3. O documento deve estar em `usuarios/{UID do Authentication}`. |
| Foto continua aguardando validação | Terminal Python, credencial Admin e conexão do computador. |
| `MissingPluginException` após atualizar | Encerre o Flutter e execute `flutter run` de novo. |
| `patch does not apply` | Envie a mensagem e o `git status --short`; não descarte mudanças locais. |

## Verificação técnica

A atualização foi verificada com Flutter 3.47.9 / Dart 3.13.7. `firebase_auth` foi mantido na série 6, compatível com `firebase_core` 4; o arquivo de dependências foi atualizado sem migrar o Firestore para outra versão principal.

Verificações locais concluídas: `flutter analyze` sem problemas; 8 testes Flutter aprovados (7 novos cenários de autenticação e o teste existente); 8 testes de regras aprovados no emulador Firestore. Os testes de interface usam um serviço de autenticação simulado; os de regras exercitam o emulador real. Não houve execução em um celular real, envio de e-mail de recuperação nem alteração no Firebase de produção por esta entrega. As etapas de configuração e o teste no seu aparelho ainda são necessários.

Para repetir os testes Flutter:

```powershell
cd "$env:USERPROFILE\Documents\PUC-Access-atualizado\app-mobile"
flutter analyze
flutter test
```

Para repetir os testes de regras (somente desenvolvimento; exige Node.js 22+ e Java 21+):

```powershell
cd "$env:USERPROFILE\Documents\PUC-Access-atualizado\tests\rules"
npm install
npm test
```

Esses testes usam `demo-puc-access` no emulador, sem credenciais de produção. O arquivo `firebase.login-test.json` serve apenas para essa execução local.

Referências oficiais:
- https://firebase.google.com/docs/auth/flutter/password-auth
- https://firebase.google.com/docs/auth/flutter/manage-users
- https://firebase.google.com/docs/firestore/security/rules-conditions
