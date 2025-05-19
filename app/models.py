from run import db
from datetime import datetime

class Ticket(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(100), nullable=False)
    cep = db.Column(db.String(20), nullable=False)
    telefone = db.Column(db.String(200), nullable=False)
    email = db.Column(db.String(200), nullable=False)
    produto = db.Column(db.String(200), nullable=False)
    descricao = db.Column(db.Text, nullable=False)
    status = db.Column(db.String(20), default="Aberto")
    data = db.Column(db.DateTime, default=datetime.utcnow) 
 

class Tecnico(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(200), nullable=False)
    senha = db.Column(db.String(200), nullable=False)
    contrato = db.Column(db.String(10), nullable=False)
    especialidade = db.Column(db.String(100), nullable=False)
    horaEntrada = db.Column(db.String(4), nullable=False)
    horaSaida = db.Column(db.String(4), nullable=False)