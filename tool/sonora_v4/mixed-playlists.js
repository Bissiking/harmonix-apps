// mixed-playlists.js — additive Harmonix v2 contract, no personal audio transfer
import express from 'express';
import { getDB } from '../db/init.js';
import { actorId, requirePermission } from '../middlewares/authorize.js';

const schemas = new WeakMap();
export async function ensureMixedPlaylistSchema(db) {
  if (!schemas.has(db)) schemas.set(db, db.exec(`
    CREATE TABLE IF NOT EXISTS harmonix_mixed_playlists (
      owner TEXT NOT NULL, id TEXT NOT NULL, revision INTEGER NOT NULL,
      operation_id TEXT NOT NULL, data TEXT NOT NULL,
      PRIMARY KEY(owner,id));
  `));
  await schemas.get(db);
}
export function normalizeMixedPlaylist(id, body) {
  if (!/^device:[a-f0-9]{32}$/.test(id)) throw new Error('invalid_id');
  if (!Number.isSafeInteger(body.baseRevision) || body.baseRevision < 0 ||
      typeof body.operationId !== 'string' || !/^[a-zA-Z0-9:_-]{16,160}$/.test(body.operationId)) throw new Error('invalid_revision');
  const name = String(body.name || '').trim();
  if (!name || name.length > 200 || !Array.isArray(body.entries) || body.entries.length > 2000) throw new Error('invalid_playlist');
  const seen = new Set();
  const entries = body.entries.map(entry => {
    if (typeof entry.trackId !== 'string' || entry.trackId.length > 200 || seen.has(entry.trackId)) throw new Error('invalid_entry');
    seen.add(entry.trackId);
    if (!['sonora', 'local'].includes(entry.source)) throw new Error('invalid_source');
    if (entry.source === 'local' && (!/^[a-f0-9]{64}$/.test(entry.fingerprint || '') || entry.trackId !== `local:${entry.fingerprint}`)) throw new Error('invalid_fingerprint');
    if (entry.source === 'sonora' && entry.trackId.startsWith('local:')) throw new Error('invalid_source');
    // Allowlisted metadata only. Paths, URLs and audio bytes never persist.
    return { trackId: entry.trackId, source: entry.source,
      ...(entry.source === 'local' ? { fingerprint: entry.fingerprint } : {}),
      title: String(entry.title || '').slice(0, 500), artist: String(entry.artist || '').slice(0, 300),
      album: String(entry.album || '').slice(0, 300), durationMs: Math.max(0, Math.min(Number(entry.durationMs) || 0, 86400000)) };
  });
  return { id, name, entries, deleted: body.deleted === true };
}

export async function saveMixedPlaylist(db, owner, id, body) {
  const data = normalizeMixedPlaylist(id, body);
  await ensureMixedPlaylistSchema(db);
  const serialized = JSON.stringify(data);
  // Atomic compare-and-swap; no shared-connection BEGIN spanning awaits.
  if (body.baseRevision === 0) {
    await db.run('INSERT OR IGNORE INTO harmonix_mixed_playlists(owner,id,revision,operation_id,data) VALUES(?,?,1,?,?)', [owner,id,body.operationId,serialized]);
  } else {
    await db.run('UPDATE harmonix_mixed_playlists SET revision=revision+1,operation_id=?,data=? WHERE owner=? AND id=? AND revision=? AND operation_id<>?',
      [body.operationId,serialized,owner,id,body.baseRevision,body.operationId]);
  }
  const row = await db.get('SELECT * FROM harmonix_mixed_playlists WHERE owner=? AND id=?', [owner,id]);
  if (row?.operation_id === body.operationId && row.data === serialized) return { conflict: false, playlist: { ...data, revision: row.revision } };
  return { conflict: true, playlist: row ? { ...JSON.parse(row.data), revision: row.revision } : null };
}
export const mixedPlaylistsRouter = express.Router();
mixedPlaylistsRouter.get('/', requirePermission('playlists:read'), async (req,res) => {
  const db = getDB(); await ensureMixedPlaylistSchema(db);
  const rows = await db.all('SELECT revision,data FROM harmonix_mixed_playlists WHERE owner=?', [actorId(req)]);
  res.json({ ok: true, data: rows.map(row => ({ ...JSON.parse(row.data), revision: row.revision })) });
});
mixedPlaylistsRouter.put('/:id', requirePermission('playlists:own'), async (req,res) => {
  let result;
  try { normalizeMixedPlaylist(req.params.id, req.body || {}); }
  catch(error) { return res.status(400).json({ok:false,error:error.message}); }
  result = await saveMixedPlaylist(getDB(), actorId(req), req.params.id, req.body);
  if(result.conflict) return res.status(409).json({ ok:false,error:'playlist_conflict',current:result.playlist });
  res.json({ok:true,data:result.playlist});
});
