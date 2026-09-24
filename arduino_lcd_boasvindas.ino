#include <Wire.h>
#include <LiquidCrystal_I2C.h>

#define ENDERECO 0x27
#define COL 16
#define LIN 2

LiquidCrystal_I2C lcd(ENDERECO, COL, LIN);

// =========================================================
// PROTOCOLO SERIAL (vindo do Raspberry Pi):
//
//   <nome>\n
//
// Exemplo enviado pelo Pi:
//   Maria Silva
//
// O Arduino NÃO grava nada em banco de dados e não tem
// relógio (RTC). Quem cuida disso é o Raspberry Pi. O Uno
// só recebe o nome e mostra a mensagem no display.
// =========================================================

const unsigned long TEMPO_EXIBICAO_BOASVINDAS = 4000; // 4s mostrando o nome
const unsigned long INTERVALO_SCROLL = 400;            // ms entre passos do scroll

enum EstadoTela {
  TELA_PADRAO,
  TELA_BOASVINDAS
};

EstadoTela estadoAtual = TELA_PADRAO;
unsigned long tempoInicioEstado = 0;

String nomeRecebido = "";
int scrollPos = 0;
unsigned long ultimoScroll = 0;

String bufferSerial = "";

void setup() {
  Serial.begin(9600);
  lcd.init();
  lcd.backlight();
  lcd.clear();
  mostrarTelaPadrao();
}

void loop() {
  lerSerial();

  unsigned long agora = millis();

  if (estadoAtual == TELA_BOASVINDAS) {
    // Scroll do nome, se ele for maior que 16 colunas
    if (nomeRecebido.length() > COL && (agora - ultimoScroll) >= INTERVALO_SCROLL) {
      ultimoScroll = agora;
      scrollNome();
    }

    // Depois do tempo definido, volta pra tela padrão
    if ((agora - tempoInicioEstado) >= TEMPO_EXIBICAO_BOASVINDAS) {
      estadoAtual = TELA_PADRAO;
      mostrarTelaPadrao();
    }
  }
}

void lerSerial() {
  while (Serial.available() > 0) {
    char c = Serial.read();
    if (c == '\n') {
      processarComando(bufferSerial);
      bufferSerial = "";
    } else if (c != '\r') {
      bufferSerial += c;
    }
  }
}

void processarComando(String linha) {
  linha.trim();

  if (linha.length() > 0) {
    exibirBoasVindas(linha);
  }
}

void exibirBoasVindas(String nome) {
  nomeRecebido = nome;
  scrollPos = 0;
  estadoAtual = TELA_BOASVINDAS;
  tempoInicioEstado = millis();
  ultimoScroll = millis();

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Seja bem-vindo!");

  lcd.setCursor(0, 1);
  if (nomeRecebido.length() <= COL) {
    lcd.print(nomeRecebido);
  } else {
    lcd.print(nomeRecebido.substring(0, COL));
  }
}

void scrollNome() {
  scrollPos++;

  String textoComEspaco = nomeRecebido + "   "; // espaço entre repetições
  if (scrollPos > (int)textoComEspaco.length()) {
    scrollPos = 0;
  }

  String textoDuplo = textoComEspaco + textoComEspaco;
  String trecho = textoDuplo.substring(scrollPos, scrollPos + COL);

  lcd.setCursor(0, 1);
  lcd.print(trecho);
}

void mostrarTelaPadrao() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Aproxime o");
  lcd.setCursor(0, 1);
  lcd.print("cartao/rosto");
}
