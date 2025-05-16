from flask import request, jsonify, render_template
from random import randint
from run import app, db

# Página inicial
@app.route('/')
def home():
    return render_template("index.html")

@app.route('/contato')
def contato():
    return render_template("contato.html")

@app.route('/cadastro')
def cadastro():
    return render_template("cadastro.html")

@app.route('/tick_fast')
def ticketapp():
    return render_template("TickFast.html")

@app.route('/contato', methods=['POST'])
def adicionar_ticket():
    try:
        from app.models import Ticket
        
        data = request.get_json()

        novo_ticket = Ticket(
            id=randint(1000,9000),
            nome=data['nome'],
            cep=data['cep'],
            telefone=data['telefone'],
            email=data['email'],
            produto=data['produto'],
            descricao=data['descricao'],
            status='aberto'
        )

        db.session.add(novo_ticket)
        db.session.commit()

        return jsonify({"message": "Ticket adicionado com sucesso!"}), 200

    except Exception as e:
        print("Erro ao adicionar ticket:", e)
        return jsonify({"error": "Erro ao adicionar ticket"}), 500
    
    
@app.route('/cadastro', methods=['POST'])
def adicionar_tecnico():
    try:
        from app.models import Tecnico
        
        data = request.get_json()

        ids_existentes = [id_tuple[0] for id_tuple in db.session.query(Tecnico.id).all()]

        while True:
            novo_id = randint(100, 300)
            if novo_id not in ids_existentes:
                break

        novo_tecnico = Tecnico(
            id=novo_id,
            nome = data['nome'],
            email = data['email'],
            senha = data['senha'],
            especialidade = data['especialidade'],
            horaEntrada = data['horaEntrada'],
            horaSaida = data['horaSaida'],
        )

        db.session.add(novo_tecnico)
        db.session.commit()
 
        return jsonify({"message": "Técnico cadastrado com sucesso!"}), 200

    except Exception as e:
        print("Erro ao cadastrar técnico:", e)
        return jsonify({"error": "Erro ao cadastrar técnico"}), 500


@app.route('/tickets', methods=['GET'])
def get_tickets():
    from app.models import Ticket
    tickets = Ticket.query.all()
    tickets_list = [
        {
            "id": ticket.id,
            "nome": ticket.nome,
            "cep": ticket.cep,
            "produto": ticket.produto,
            "status": ticket.status,
            "data": ticket.data.isoformat()
        }
        for ticket in tickets
    ]
    return jsonify(tickets_list)


@app.route('/api/login', methods=['POST'])
def login():
    from app.models import Tecnico
    data = request.json

    identificador = data.get('email')  # pode ser email ou id (ambos vêm no mesmo campo no Flutter)
    senha = data.get('senha')

    if not identificador or not senha:
        return jsonify({'error': 'Campos obrigatórios faltando'}), 400

    # Tenta encontrar por email ou por ID numérico
    tecnico = Tecnico.query.filter(
        (Tecnico.email == identificador) | (Tecnico.id == identificador)
    ).first()

    if tecnico and tecnico.senha == senha:
        return jsonify({
            'status': 'sucesso',
            'id': tecnico.id,
            'nome': tecnico.nome,
            'email': tecnico.email,
            'token': '123456abc',
        })
    else:
        return jsonify({'status': 'erro', 'mensagem': 'Credenciais inválidas'}), 401
