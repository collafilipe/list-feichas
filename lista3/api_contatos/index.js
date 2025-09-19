const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3000;
const CONTACTS_FILE = path.join(__dirname, 'contatos.json');

app.use(cors());
app.use(bodyParser.json());

function readContacts() {
  try {
    if (!fs.existsSync(CONTACTS_FILE)) {
      return [];
    }
    const data = fs.readFileSync(CONTACTS_FILE, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    console.error('Erro ao ler contatos:', error);
    return [];
  }
}

function saveContacts(contacts) {
  try {
    fs.writeFileSync(CONTACTS_FILE, JSON.stringify(contacts, null, 2));
    return true;
  } catch (error) {
    console.error('Erro ao salvar contatos:', error);
    return false;
  }
}

function generateId() {
  return Date.now().toString();
}

app.get('/contatos', (req, res) => {
  try {
    const contacts = readContacts();
    res.json({
      success: true,
      data: contacts,
      message: 'Contatos recuperados com sucesso'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Erro interno do servidor',
      message: error.message
    });
  }
});

app.get('/contatos/:id', (req, res) => {
  try {
    const { id } = req.params;
    const contacts = readContacts();
    const contact = contacts.find(c => c.id === id);
    
    if (!contact) {
      return res.status(404).json({
        success: false,
        error: 'Contato não encontrado',
        message: `Contato com ID ${id} não existe`
      });
    }
    
    res.json({
      success: true,
      data: contact,
      message: 'Contato encontrado com sucesso'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Erro interno do servidor',
      message: error.message
    });
  }
});

app.post('/contatos', (req, res) => {
  try {
    const { nome, telefone, email } = req.body;
    
    if (!nome || !telefone) {
      return res.status(400).json({
        success: false,
        error: 'Dados inválidos',
        message: 'Nome e telefone são obrigatórios'
      });
    }
    
    const contacts = readContacts();
    const newContact = {
      id: generateId(),
      nome: nome.trim(),
      telefone: telefone.trim(),
      email: email ? email.trim() : '',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    
    contacts.push(newContact);
    
    if (saveContacts(contacts)) {
      res.status(201).json({
        success: true,
        data: newContact,
        message: 'Contato criado com sucesso'
      });
    } else {
      throw new Error('Falha ao salvar contato');
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Erro interno do servidor',
      message: error.message
    });
  }
});

app.put('/contatos/:id', (req, res) => {
  try {
    const { id } = req.params;
    const { nome, telefone, email } = req.body;
    
    if (!nome || !telefone) {
      return res.status(400).json({
        success: false,
        error: 'Dados inválidos',
        message: 'Nome e telefone são obrigatórios'
      });
    }
    
    const contacts = readContacts();
    const contactIndex = contacts.findIndex(c => c.id === id);
    
    if (contactIndex === -1) {
      return res.status(404).json({
        success: false,
        error: 'Contato não encontrado',
        message: `Contato com ID ${id} não existe`
      });
    }
    
    const updatedContact = {
      ...contacts[contactIndex],
      nome: nome.trim(),
      telefone: telefone.trim(),
      email: email ? email.trim() : '',
      updatedAt: new Date().toISOString()
    };
    
    contacts[contactIndex] = updatedContact;
    
    if (saveContacts(contacts)) {
      res.json({
        success: true,
        data: updatedContact,
        message: 'Contato atualizado com sucesso'
      });
    } else {
      throw new Error('Falha ao atualizar contato');
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Erro interno do servidor',
      message: error.message
    });
  }
});

app.delete('/contatos/:id', (req, res) => {
  try {
    const { id } = req.params;
    const contacts = readContacts();
    const contactIndex = contacts.findIndex(c => c.id === id);
    
    if (contactIndex === -1) {
      return res.status(404).json({
        success: false,
        error: 'Contato não encontrado',
        message: `Contato com ID ${id} não existe`
      });
    }
    
    const deletedContact = contacts[contactIndex];
    contacts.splice(contactIndex, 1);
    
    if (saveContacts(contacts)) {
      res.json({
        success: true,
        data: deletedContact,
        message: 'Contato excluído com sucesso'
      });
    } else {
      throw new Error('Falha ao excluir contato');
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Erro interno do servidor',
      message: error.message
    });
  }
});

app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Rota não encontrada',
    message: `Rota ${req.method} ${req.originalUrl} não existe`
  });
});

app.use((error, req, res, next) => {
  console.error('Erro não tratado:', error);
  res.status(500).json({
    success: false,
    error: 'Erro interno do servidor',
    message: 'Algo deu errado no servidor'
  });
});

app.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`);
  console.log(`API disponível em: http://localhost:${PORT}`);
  
  if (!fs.existsSync(CONTACTS_FILE)) {
    saveContacts([]);
    console.log('Arquivo de contatos inicializado');
  }
});