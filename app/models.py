from run import db
from datetime import datetime

class Tecnico(db.Model):
    __tablename__ = 'tecnicos'
    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(200), nullable=False)
    senha = db.Column(db.String(200), nullable=False)
    contrato = db.Column(db.String(10), nullable=False)
    especialidade = db.Column(db.String(100), nullable=False)
    horaEntrada = db.Column(db.String(4), nullable=False)
    horaSaida = db.Column(db.String(4), nullable=False)
    status = db.Column(db.String(30), nullable=False)
    imagem = db.Column(db.String(200), default='user_placeholder.png')
    token = db.Column(db.String(30), default='123456abc')

    tickets = db.relationship('Ticket', back_populates='tecnico')

# Ticket
class Ticket(db.Model):
    __tablename__ = 'tickets'
    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(100))
    cep = db.Column(db.String(20))
    telefone = db.Column(db.String(20))
    email = db.Column(db.String(100))
    produto = db.Column(db.String(100))
    descricao = db.Column(db.Text)
    data = db.Column(db.DateTime, default=datetime.utcnow, nullable=True)
    status = db.Column(db.String(50), default='Aberto')

    tecnico_id = db.Column(db.Integer, db.ForeignKey('tecnicos.id'))
    tecnico = db.relationship('Tecnico', back_populates='tickets')