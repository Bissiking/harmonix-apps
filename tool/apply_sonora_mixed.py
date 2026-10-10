# apply_sonora_mixed.py
from pathlib import Path
root = Path(r'D:/DEV/NODEJS/sonora')
source = Path(__file__).parent / 'sonora_v4'
adapter = root / 'routes/harmonix.js'
text = adapter.read_text(encoding='utf-8')
assert 'mixedPlaylistsRouter' not in text
text = text.replace('const router = express.Router();', 'import { mixedPlaylistsRouter } from "./mixed-playlists.js";\n\nconst router = express.Router();\nrouter.use("/v2/mixed-playlists", mixedPlaylistsRouter);', 1)
text = text.replace('      playlists: true,', '      playlists: true,\n      mixed_playlists: true,', 1)
(root / 'routes/mixed-playlists.js').write_text((source / 'mixed-playlists.js').read_text(encoding='utf-8'), encoding='utf-8')
(root / 'test/mixed-playlists.test.js').write_text((source / 'mixed-playlists.test.js').read_text(encoding='utf-8'), encoding='utf-8')
adapter.write_text(text, encoding='utf-8')
print('Added account-scoped mixed playlists with CAS revisions and tests.')
