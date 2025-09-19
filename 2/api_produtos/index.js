const express = require('express');
const cors = require('cors');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

app.use((req, _res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

const dbPath = path.join(__dirname, 'produtos.db');
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Erro ao abrir o banco SQLite:', err);
  } else {
    console.log('SQLite aberto em:', dbPath);
  }
});

db.serialize(() => {
  db.run(`
    CREATE TABLE IF NOT EXISTS produtos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT NOT NULL,
      preco REAL NOT NULL,
      descricao TEXT,
      updated_at TEXT
    )
  `, (e) => e && console.error('Erro CREATE TABLE:', e));

  db.all(`PRAGMA table_info(produtos)`, (err, cols) => {
    if (err) {
      console.error('Erro ao obter schema:', err);
      return;
    }
    const hasUpdatedAt = Array.isArray(cols) && cols.some(c => c.name === 'updated_at');

    const afterMigration = () => {
      db.get('SELECT COUNT(*) AS count FROM produtos', (err2, row) => {
        if (err2) {
          console.error('Erro ao contar produtos:', err2);
          return;
        }
        if ((row?.count ?? 0) === 0) {
          const now = new Date().toISOString();
          const stmt = db.prepare(
            'INSERT INTO produtos (nome, preco, descricao, updated_at) VALUES (?, ?, ?, ?)'
          );
          [
            ['Camiseta Tech', 59.9, 'Camiseta 100% algodão premium', now],
            ['Mouse Gamer X', 129.0, 'RGB, 6 botões programáveis', now],
            ['Fone Bluetooth', 199.9, 'Cancelamento de ruído e estojo de carga', now],
          ].forEach(p => stmt.run(p[0], p[1], p[2], p[3]));
          stmt.finalize();
          console.log('Seed inicial inserido em produtos.db');
        }
      });
    };

    if (!hasUpdatedAt) {
      console.log('Coluna "updated_at" ausente. Aplicando migração...');
      db.run(`ALTER TABLE produtos ADD COLUMN updated_at TEXT`, (err3) => {
        if (err3) {
          console.error('Erro ao adicionar coluna updated_at (pode ser inofensivo se já existe):', err3.message);
        }
        const now = new Date().toISOString();
        db.run(
          `UPDATE produtos SET updated_at = ? WHERE updated_at IS NULL OR updated_at = ''`,
          [now],
          (err4) => {
            if (err4) console.error('Erro ao popular updated_at:', err4);
            else console.log('Migração concluída: updated_at criada e populada.');
            afterMigration();
          }
        );
      });
    } else {
      afterMigration();
    }
  });
});

app.get('/health', (_req, res) => res.json({ ok: true }));

app.get('/produtos', (_req, res) => {
  db.all(
    'SELECT id, nome, preco, descricao, updated_at FROM produtos ORDER BY id DESC',
    (err, rows) => {
      if (err) {
        console.error('Erro ao buscar produtos:', err);
        return res.status(500).json({ error: 'Erro ao buscar produtos' });
      }
      res.json(rows);
    }
  );
});

app.get('/produtos/:id', (req, res) => {
  const { id } = req.params;
  db.get(
    'SELECT id, nome, preco, descricao, updated_at FROM produtos WHERE id = ?',
    [id],
    (err, row) => {
      if (err) {
        console.error('Erro ao buscar produto:', err);
        return res.status(500).json({ error: 'Erro ao buscar produto' });
      }
      if (!row) return res.status(404).json({ error: 'Produto não encontrado' });
      res.json(row);
    }
  );
});

app.post('/produtos', (req, res) => {
  const { nome, preco, descricao = '' } = req.body;
  const erros = [];
  if (typeof nome !== 'string' || !nome.trim()) erros.push('nome inválido');
  if (Number.isNaN(Number(preco))) erros.push('preco inválido');
  if (erros.length) return res.status(400).json({ errors: erros });

  const now = new Date().toISOString();
  db.run(
    'INSERT INTO produtos (nome, preco, descricao, updated_at) VALUES (?, ?, ?, ?)',
    [nome.trim(), Number(preco), descricao, now],
    function (err) {
      if (err) {
        console.error('Erro ao criar produto:', err);
        return res.status(500).json({ error: 'Erro ao criar produto' });
      }
      const id = this.lastID;
      db.get(
        'SELECT id, nome, preco, descricao, updated_at FROM produtos WHERE id = ?',
        [id],
        (err2, row) => {
          if (err2 || !row) {
            if (err2) console.error('Erro ao recuperar produto criado:', err2);
            return res.status(201).json({ id, nome, preco, descricao, updated_at: now });
          }
          res.status(201).json(row);
        }
      );
    }
  );
});

app.put('/produtos/:id', (req, res) => {
  const { id } = req.params;
  db.get('SELECT * FROM produtos WHERE id = ?', [id], (err, row) => {
    if (err) {
      console.error('Erro ao buscar produto para update:', err);
      return res.status(500).json({ error: 'Erro ao atualizar produto' });
    }
    if (!row) return res.status(404).json({ error: 'Produto não encontrado' });

    const novoNome = req.body.nome !== undefined ? String(req.body.nome).trim() : row.nome;
    const novoPreco = req.body.preco !== undefined ? Number(req.body.preco) : Number(row.preco);
    const novaDescricao = req.body.descricao !== undefined ? String(req.body.descricao) : row.descricao;

    const errs = [];
    if (!novoNome) errs.push('nome inválido');
    if (Number.isNaN(novoPreco)) errs.push('preco inválido');
    if (errs.length) return res.status(400).json({ errors: errs });

    const now = new Date().toISOString();
    db.run(
      'UPDATE produtos SET nome = ?, preco = ?, descricao = ?, updated_at = ? WHERE id = ?',
      [novoNome, novoPreco, novaDescricao, now, id],
      function (err2) {
        if (err2) {
          console.error('Erro ao atualizar produto:', err2);
          return res.status(500).json({ error: 'Erro ao atualizar produto' });
        }
        db.get(
          'SELECT id, nome, preco, descricao, updated_at FROM produtos WHERE id = ?',
          [id],
          (err3, atualizado) => {
            if (err3) {
              console.error('Erro ao recuperar produto atualizado:', err3);
              return res.json({
                id: Number(id),
                nome: novoNome,
                preco: novoPreco,
                descricao: novaDescricao,
                updated_at: now,
              });
            }
            res.json(atualizado);
          }
        );
      }
    );
  });
});

app.delete('/produtos/:id', (req, res) => {
  const { id } = req.params;
  db.get(
    'SELECT id, nome, preco, descricao, updated_at FROM produtos WHERE id = ?',
    [id],
    (err, row) => {
      if (err) {
        console.error('Erro ao buscar produto para exclusão:', err);
        return res.status(500).json({ error: 'Erro ao excluir produto' });
      }
      if (!row) return res.status(404).json({ error: 'Produto não encontrado' });

      db.run('DELETE FROM produtos WHERE id = ?', [id], function (err2) {
        if (err2) {
          console.error('Erro ao excluir produto:', err2);
          return res.status(500).json({ error: 'Erro ao excluir produto' });
        }
        res.json({ deleted: true, produto: row });
      });
    }
  );
});

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`API rodando em http://localhost:${PORT}`);
  console.log(`DB em: ${dbPath}`);
});

server.on('error', (err) => {
  console.error('Falha ao subir o servidor:', err.code || err.message, err);
  if (err.code === 'EADDRINUSE') {
    console.error(`Porta ${PORT} já está em uso. Finalize o processo que a ocupa (veja abaixo).`);
    console.error(`Dica: lsof -nP -iTCP:${PORT} -sTCP:LISTEN`);
  }
  process.exit(1);
});

process.on('uncaughtException', (err) => {
  console.error('UncaughtException:', err);
});
process.on('unhandledRejection', (reason, p) => {
  console.error('UnhandledRejection:', reason, 'em', p);
});

process.on('SIGINT', () => {
  console.log('Encerrando por SIGINT...');
  server.close(() => process.exit(0));
});
