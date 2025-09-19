const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(bodyParser.json());

const tarefasFilePath = path.join(__dirname, 'tarefas.json');

const readTarefasFile = () => {
  try {
    const tarefasData = fs.readFileSync(tarefasFilePath, 'utf8');
    return JSON.parse(tarefasData);
  } catch (error) {
    if (error.code === 'ENOENT') {
      fs.writeFileSync(tarefasFilePath, JSON.stringify([]));
      return [];
    }
    console.error('Erro ao ler o arquivo de tarefas:', error);
    return [];
  }
};

const writeTarefasFile = (tarefas) => {
  try {
    fs.writeFileSync(tarefasFilePath, JSON.stringify(tarefas, null, 2));
  } catch (error) {
    console.error('Erro ao escrever no arquivo de tarefas:', error);
  }
};

app.get('/tarefas', (req, res) => {
  const tarefas = readTarefasFile();
  res.json(tarefas);
});

app.post('/tarefas', (req, res) => {
  const tarefas = readTarefasFile();
  const novaTarefa = {
    id: Date.now().toString(), 
    titulo: req.body.titulo,
    descricao: req.body.descricao,
    concluida: false,
    dataCriacao: new Date().toISOString()
  };
  
  tarefas.push(novaTarefa);
  writeTarefasFile(tarefas);
  
  res.status(201).json(novaTarefa);
});

app.put('/tarefas/:id', (req, res) => {
  const id = req.params.id;
  const tarefas = readTarefasFile();
  const index = tarefas.findIndex(tarefa => tarefa.id === id);
  
  if (index === -1) {
    return res.status(404).json({ error: 'Tarefa não encontrada' });
  }
  
  const tarefaAtualizada = {
    ...tarefas[index],
    ...req.body,
    id: id 
  };
  
  tarefas[index] = tarefaAtualizada;
  writeTarefasFile(tarefas);
  
  res.json(tarefaAtualizada);
});

app.delete('/tarefas/:id', (req, res) => {
  const id = req.params.id;
  const tarefas = readTarefasFile();
  const index = tarefas.findIndex(tarefa => tarefa.id === id);
  
  if (index === -1) {
    return res.status(404).json({ error: 'Tarefa não encontrada' });
  }
  
  const tarefaRemovida = tarefas.splice(index, 1)[0];
  writeTarefasFile(tarefas);
  
  res.json(tarefaRemovida);
});

app.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`);
});
