# Integração com Firebase — PUC Access

Esta pasta contém a camada de integração entre o sistema de controle de acesso e o Firebase/Cloud Firestore.

O projeto faz parte do trabalho da disciplina de **Sistemas Embarcados** e possui como sistema central um **Raspberry Pi 5**, responsável pela catraca/totem. O sistema utilizará reconhecimento facial e RFID (RC522) como métodos de identificação.

> Neste momento, a integração física com o Raspberry Pi e com o leitor RC522 ainda não foi realizada. Os testes atuais utilizam UIDs RFID simulados.

---

## Arquitetura atual

```text
Flutter App
    │
    │ cadastra usuários
    ▼
Cloud Firestore
    ▲
    │
API Python / database
    ▲
    │
Raspberry Pi 5
    │
    ├── RC522 (RFID)
    ├── Webcam
    ├── Servo motor
    └── Display
```

O aplicativo Flutter e a parte de hardware utilizam o mesmo banco de dados no Firebase.

A pasta `database/` concentra a integração Python com o Firestore e a API que futuramente será utilizada pelo Raspberry Pi.

---

## Estrutura da pasta

```text
database/
├── firebase_config.py
├── firebase_credentials.json
├── rfid_service.py
├── acesso_service.py
├── api.py
├── teste_conexao.py
├── teste_rfid.py
└── README.md
```

### `firebase_config.py`

Inicializa o Firebase Admin SDK e disponibiliza a conexão com o Cloud Firestore para os demais módulos Python.

### `rfid_service.py`

Responsável por consultar usuários através do UID de um cartão RFID.

Atualmente é possível buscar um usuário através de um UID como:

```text
B79F1415
```

### `acesso_service.py`

Responsável por registrar no Firestore as tentativas de acesso realizadas no sistema.

São armazenadas informações como:

- usuário;
- método de acesso;
- resultado da autorização;
- dispositivo;
- data e hora.

### `api.py`

API Flask utilizada como camada de comunicação com o sistema.

Atualmente permite testar a validação de um RFID através de:

```text
GET /rfid/<uid>
```

Exemplo:

```text
/rfid/B79F1415
```

Um RFID cadastrado retorna uma resposta semelhante a:

```json
{
  "autorizado": true,
  "nome": "marcos",
  "rfid": "B79F1415",
  "usuarioId": "ID_DO_USUARIO"
}
```

Um RFID não cadastrado retorna:

```json
{
  "autorizado": false,
  "rfid": "12345678",
  "mensagem": "RFID nao cadastrado"
}
```

As duas situações são registradas na coleção `acessos`.

### `teste_conexao.py`

Teste simples utilizado para verificar a conexão Python → Firebase e listar os usuários existentes no Firestore.

### `teste_rfid.py`

Teste da consulta de um UID RFID sem necessidade do hardware físico.

---

# Estrutura atual do Firestore

## Coleção `usuarios`

Armazena os usuários cadastrados pelo aplicativo.

Exemplo:

```text
usuarios
└── ID_USUARIO
    ├── nome: "marcos"
    ├── rfid: "B79F1415"
    ├── consentimento: true
    ├── cadastroConcluido: true
    └── criadoEm: timestamp
```

Neste momento o RFID foi associado manualmente no Firestore para permitir os testes da integração.

Futuramente o UID deverá ser obtido diretamente pelo leitor RC522 durante o processo de associação do cartão ao usuário.

---

## Coleção `acessos`

Registra tentativas de entrada no sistema.

Exemplo de acesso autorizado:

```text
acessos
└── ID_ACESSO
    ├── usuarioId: "ID_USUARIO"
    ├── nome: "marcos"
    ├── metodo: "rfid"
    ├── autorizado: true
    ├── dispositivoId: "entrada_01"
    └── dataHora: timestamp
```

Tentativas utilizando cartões não cadastrados também são registradas com:

```text
autorizado: false
usuarioId: null
nome: null
```

---

# Executando o projeto

## Dependências

É necessário ter Python instalado.

Instale as dependências utilizadas atualmente:

```bash
py -m pip install firebase-admin flask
```

---

## Credencial do Firebase

O Firebase Admin SDK utiliza uma chave privada.

O arquivo utilizado localmente é:

```text
database/firebase_credentials.json
```

Por segurança, esse arquivo **não deve ser enviado para o repositório Git**.

O `.gitignore` da raiz deve conter:

```gitignore
database/firebase_credentials.json
```

Cada ambiente que executar a API (computador de desenvolvimento ou Raspberry Pi) deverá possuir sua própria credencial válida.

---

# Testando a conexão com o Firebase

Na raiz do repositório:

```bash
py database/teste_conexao.py
```

O programa deverá listar os usuários existentes na coleção `usuarios`.

---

# Testando RFID sem hardware

Execute:

```bash
py database/teste_rfid.py
```

O teste utiliza um UID cadastrado para verificar se o usuário correspondente pode ser encontrado no Firestore.

---

# Executando a API

Na raiz do projeto:

```bash
py database/api.py
```

Durante o desenvolvimento, a API Flask utiliza a porta:

```text
5000
```

Exemplo local:

```text
http://127.0.0.1:5000
```

---

# Estado atual da integração RFID

Já implementado:

- conexão Python com Firebase Admin SDK;
- leitura da coleção `usuarios`;
- busca de usuário através do UID RFID;
- identificação de RFID cadastrado;
- identificação de RFID não cadastrado;
- registro de acessos autorizados;
- registro de tentativas negadas;
- API Flask para teste da validação;
- integração Flutter → Firestore funcionando;
- testes sem necessidade do hardware físico.

Ainda pendente:

- integração física com Raspberry Pi 5;
- leitura real do RC522;
- cadastro de RFID utilizando o leitor;
- comunicação do fluxo de cadastro com o aplicativo;
- substituição dos UIDs simulados pela leitura real;
- integração com servo motor;
- integração com display;
- regras definitivas de segurança do Firestore;
- autenticação definitiva da API;
- integração do reconhecimento facial.

---

# Fluxo RFID planejado

## Verificação

```text
Cartão
  ↓
RC522
  ↓
Raspberry Pi 5
  ↓
Sistema consulta UID
  ↓
Firestore / usuarios
  ↓
┌───────────────┐
│ UID cadastrado?│
└───────┬───────┘
        │
    SIM │ NÃO
        │
        ↓
AUTORIZADO / NEGADO
        ↓
registro em acessos
        ↓
servo motor (quando autorizado)
```

## Cadastro

O fluxo planejado para associação de novos cartões é:

```text
Aplicativo
    ↓
seleciona usuário
    ↓
solicita cadastro RFID
    ↓
Raspberry Pi entra em modo de cadastro
    ↓
usuário aproxima cartão
    ↓
RC522 lê UID
    ↓
UID é associado ao usuário
    ↓
Firestore
```

A implementação desse fluxo será realizada posteriormente, quando houver acesso ao hardware físico.

---

# Observação sobre reconhecimento facial

O reconhecimento facial é uma parte independente do desenvolvimento atual do RFID.

A arquitetura definida pelo projeto prevê o cadastro facial no aplicativo e o reconhecimento na catraca utilizando o mesmo modelo de embedding nas duas plataformas.

A integração definitiva dessa funcionalidade será realizada em uma etapa posterior.