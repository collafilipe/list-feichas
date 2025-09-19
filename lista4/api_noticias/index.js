const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');

const app = express();
const port = 3000;

app.use(cors());
app.use(bodyParser.json());

const lerNoticias = () => {
  try {
    const data = fs.readFileSync(path.join(__dirname, 'noticias.json'), 'utf8');
    return JSON.parse(data);
  } catch (error) {
    console.error('Erro ao ler arquivo de notícias:', error);
    return [];
  }
};

app.get('/noticias', (req, res) => {
  try {
    const noticias = lerNoticias();
    res.json({
      success: true,
      data: noticias,
      message: 'Notícias carregadas com sucesso'
    });
  } catch (error) {
    console.error('Erro ao buscar notícias:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor'
    });
  }
});

app.get('/', (req, res) => {
  res.json({
    message: 'API de Notícias funcionando!',
    version: '1.0.0',
    endpoints: [
      'GET /noticias - Lista todas as notícias'
    ]
  });
});

app.listen(port, () => {
  console.log(`Servidor rodando em http://localhost:${port}`);
});

module.exports = app;
