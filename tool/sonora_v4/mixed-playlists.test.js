// mixed-playlists.test.js
import test from 'node:test';
import assert from 'node:assert/strict';
import { open } from 'sqlite';
import sqlite3 from 'sqlite3';
import { saveMixedPlaylist, normalizeMixedPlaylist } from '../routes/mixed-playlists.js';
const id = 'device:' + 'a'.repeat(32);
const initial = { baseRevision:0,operationId:'operation-create-0001',name:'Mix',entries:[
  {trackId:'sonora-1',source:'sonora',title:'Remote'},
  {trackId:'local:'+'b'.repeat(64),source:'local',fingerprint:'b'.repeat(64),title:'Personal',path:'C:/private/audio.mp3'}] };
test('mixed playlists preserve local references without transferring paths', () => {
  const normalized = normalizeMixedPlaylist(id,initial);
  assert.equal(normalized.entries.length,2);
  assert.equal(normalized.entries[1].path,undefined);
  assert.throws(() => normalizeMixedPlaylist(id,{...initial,entries:[{trackId:'local:x',source:'local',fingerprint:'x'}]}));
});
test('revision conflicts and replayed operations never duplicate or overwrite edits', async () => {
  const db = await open({filename:':memory:',driver:sqlite3.Database});
  try {
    assert.equal((await saveMixedPlaylist(db,'owner',id,initial)).playlist.revision,1);
    assert.equal((await saveMixedPlaylist(db,'owner',id,initial)).playlist.revision,1);
    const update = {...initial,baseRevision:1,operationId:'operation-update-0002',name:'Updated'};
    const results = await Promise.all([
      saveMixedPlaylist(db,'owner',id,update),
      saveMixedPlaylist(db,'owner',id,{...update,operationId:'operation-stale-0003',name:'Stale'})]);
    assert.equal(results.filter(r => !r.conflict).length,1);
    const replay = await saveMixedPlaylist(db,'owner',id,initial);
    assert.equal(replay.conflict,true);
    assert.equal(replay.playlist.revision,2);
    assert.equal((await saveMixedPlaylist(db,'another-owner',id,initial)).playlist.revision,1);
  } finally { await db.close(); }
});
