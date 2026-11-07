import { after, before, beforeEach, test } from 'node:test';
import { readFile } from 'node:fs/promises';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { Bytes, collection, deleteDoc, deleteField, doc, getDoc, getDocs, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';

let env;
const projeto = 'demo-puc-access';
before(async () => {
  env = await initializeTestEnvironment({
    projectId: projeto,
    firestore: { rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8') },
  });
});
beforeEach(async () => { await env.clearFirestore(); });
after(async () => { await env?.cleanup(); });

function banco(uid = 'alice') {
  return env.authenticatedContext(uid, { email: `${uid}@example.com` }).firestore();
}
function cadastro(uid = 'alice', versao = 'foto-1') {
  return {
    uid, email: `${uid}@example.com`, nome: 'Pessoa de teste',
    consentimento: true, cadastroConcluido: false, fotoVersao: versao,
    facialStatus: 'pendente', facialMensagem: 'Aguardando validação da foto.',
    atualizadoEm: serverTimestamp(), criadoEm: serverTimestamp(), fotoSalvaEm: serverTimestamp(),
    fotoRosto: Bytes.fromUint8Array(new Uint8Array([1, 2, 3])), fotoTamanhoBytes: 3,
  };
}

test('conta cria e lê seu cadastro', async () => {
  const ref = doc(banco(), 'usuarios/alice');
  await assertSucceeds(setDoc(ref, cadastro()));
  await assertSucceeds(getDoc(ref));
});

test('anônimo não lê nem grava cadastro', async () => {
  const ref = doc(env.unauthenticatedContext().firestore(), 'usuarios/alice');
  await assertFails(getDoc(ref));
  await assertFails(setDoc(ref, cadastro()));
});

test('outra conta não lê nem altera e não pode listar usuários', async () => {
  await setDoc(doc(banco(), 'usuarios/alice'), cadastro());
  const bob = banco('bob');
  await assertFails(getDoc(doc(bob, 'usuarios/alice')));
  await assertFails(setDoc(doc(bob, 'usuarios/alice'), cadastro('bob')));
  await assertFails(getDocs(collection(banco(), 'usuarios')));
});

test('não aceita identidade forjada, senha ou aprovação pelo cliente', async () => {
  const ref = doc(banco(), 'usuarios/alice');
  for (const adulteracao of [
    { uid: 'bob' }, { email: 'bob@example.com' }, { senha: 'segredo' },
    { facialStatus: 'pronto', cadastroConcluido: true }, { facialEmbedding: [1, 2] },
    { facialResultadoVersao: 'foto-1' }, { consentimento: false },
  ]) {
    await assertFails(setDoc(ref, { ...cadastro(), ...adulteracao }));
  }
});

test('valida tamanho da foto e não permite excluir cadastro pelo cliente', async () => {
  const ref = doc(banco(), 'usuarios/alice');
  await assertFails(setDoc(ref, { ...cadastro(), fotoTamanhoBytes: 10 }));
  await assertFails(setDoc(ref, {
    ...cadastro(), fotoRosto: Bytes.fromUint8Array(new Uint8Array(716801)), fotoTamanhoBytes: 716801,
  }));
  await assertSucceeds(setDoc(ref, cadastro()));
  await assertFails(deleteDoc(ref));
});

test('Python/Admin aprova; cliente só pode reenviar removendo resultado anterior', async () => {
  const ref = doc(banco(), 'usuarios/alice');
  await setDoc(ref, cadastro());
  await env.withSecurityRulesDisabled(async (context) => {
    await updateDoc(doc(context.firestore(), 'usuarios/alice'), {
      facialStatus: 'pronto', cadastroConcluido: true, facialEmbedding: [0.1, 0.2],
      facialModelo: 'modelo', facialFotoHash: 'hash', facialResultadoVersao: 'foto-1',
      facialProcessadoEm: serverTimestamp(),
    });
  });
  await assertSucceeds(getDoc(ref));
  const novo = cadastro('alice', 'foto-2');
  delete novo.criadoEm;
  await assertFails(setDoc(ref, novo, { merge: true }));
  await assertSucceeds(setDoc(ref, {
    ...novo, facialEmbedding: deleteField(), facialModelo: deleteField(),
    facialFotoHash: deleteField(), facialResultadoVersao: deleteField(), facialProcessadoEm: deleteField(),
  }, { merge: true }));
  await assertFails(setDoc(ref, novo, { merge: true })); // versão repetida
});

test('coleções antigas e registros de acesso não ficam públicos', async () => {
  for (const caminho of ['usuario/antigo', 'acessos/evento']) {
    await assertFails(getDoc(doc(banco(), caminho)));
    await assertFails(setDoc(doc(banco(), caminho), { nome: 'teste' }));
  }
});

test('reenvio preserva RFID do administrador e não permite adulterá-lo', async () => {
  const ref = doc(banco(), 'usuarios/alice');
  await setDoc(ref, cadastro());
  await env.withSecurityRulesDisabled(async (context) => {
    await updateDoc(doc(context.firestore(), 'usuarios/alice'), { rfid: 'ABC123' });
  });
  const novo = cadastro('alice', 'foto-2');
  delete novo.criadoEm;
  await assertFails(setDoc(ref, { ...novo, rfid: 'OUTRO' }, { merge: true }));
  await assertSucceeds(setDoc(ref, novo, { merge: true }));
});

test('cliente edita só o nome, sem alterar foto, status ou RFID', async () => {
  const ref = doc(banco(), 'usuarios/alice');
  await setDoc(ref, cadastro());
  await assertSucceeds(updateDoc(ref, { nome: 'Novo Nome', atualizadoEm: serverTimestamp() }));
  await assertFails(updateDoc(ref, { nome: '', atualizadoEm: serverTimestamp() }));
  await assertFails(updateDoc(ref, { nome: 'x'.repeat(201), atualizadoEm: serverTimestamp() }));
  await assertFails(updateDoc(ref, { nome: 'Outro', atualizadoEm: serverTimestamp(), facialStatus: 'pronto' }));
  await assertFails(updateDoc(ref, { nome: 'Outro', atualizadoEm: serverTimestamp(), rfid: 'X' }));
  await assertFails(updateDoc(doc(banco('bob'), 'usuarios/alice'), { nome: 'Invasor', atualizadoEm: serverTimestamp() }));
});

test('cadastro aceita a escolha de NFC e ela pode ser mudada depois', async () => {
  const ref = doc(banco(), 'usuarios/alice');
  await assertSucceeds(setDoc(ref, { ...cadastro(), nfcAutorizado: false, nfcDecididoEm: serverTimestamp() }));
  await assertSucceeds(updateDoc(ref, { nfcAutorizado: true, nfcDecididoEm: serverTimestamp() }));
  await assertSucceeds(updateDoc(ref, { nfcAutorizado: false, nfcDecididoEm: serverTimestamp() }));
});

test('escolha de NFC rejeita valor inválido, campos extras e outra conta', async () => {
  const ref = doc(banco(), 'usuarios/alice');
  await assertFails(setDoc(ref, { ...cadastro(), nfcAutorizado: 'sim', nfcDecididoEm: serverTimestamp() }));
  await setDoc(ref, cadastro());
  await assertFails(updateDoc(ref, { nfcAutorizado: 'sim', nfcDecididoEm: serverTimestamp() }));
  await assertFails(updateDoc(ref, { nfcAutorizado: true, nfcDecididoEm: serverTimestamp(), rfid: 'X' }));
  await assertFails(updateDoc(ref, { nfcAutorizado: true, nfcDecididoEm: serverTimestamp(), facialStatus: 'pronto' }));
  await assertFails(updateDoc(doc(banco('bob'), 'usuarios/alice'), { nfcAutorizado: true, nfcDecididoEm: serverTimestamp() }));
});
