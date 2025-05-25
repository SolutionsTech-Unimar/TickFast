from flask import request,current_app,jsonify, render_template,url_for
from random import randint
from app.services import distribuir_ticket, extensao_permitida
from werkzeug.utils import secure_filename
from run import app, db
import os
import time

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

        distribuir_ticket(novo_ticket)

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
            contrato = data['contrato'],
            especialidade = data['especialidade'],
            horaEntrada = data['horaEntrada'],
            horaSaida = data['horaSaida'],
            status = 'inativo'
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
    result = []
    for t in tickets:
        result.append({
            "id": t.id,
            "nome": t.nome,
            "cep": t.cep,
            "telefone": t.telefone,
            "email": t.email,
            "produto": t.produto,
            "descricao": t.descricao,
            "status": t.status,
            "tecnico": t.tecnico.nome if t.tecnico else None,
            "data": t.data.isoformat()
        })
    return jsonify(result)


@app.route('/tecnicos', methods=['GET'])
def get_tecnicos():
    from app.models import Tecnico

    tecnicos = Tecnico.query.all()
    result = []
    for t in tecnicos:
        result.append({
            "id": t.id,
            "nome": t.nome,
            "email": t.email,
            "especialidade": t.especialidade,
            "status": t.status,
            "imagem": url_for('static', filename=f'fotos_perfil/{t.imagem}'),
            "tickets": [  # tickets vinculados ao técnico
                {
                    "id": ticket.id,
                    "produto": ticket.produto,
                    "status": ticket.status,
                }
                for ticket in t.tickets
            ],
            "tickets_abertos": len([tk for tk in t.tickets if tk.status != "Encerrado"])
        })
    return jsonify(result)


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
            'statusApi': 'sucesso',
            'id': tecnico.id,
            'nome': tecnico.nome,
            'email': tecnico.email,
            'imagem': tecnico.imagem,
            'horaEntrada': tecnico.horaEntrada,
            'horaSaida': tecnico.horaSaida,
            'status': tecnico.status,
            'token': tecnico.token,
        })
    else:
        return jsonify({'status': 'erro', 'mensagem': 'Credenciais inválidas'}), 401
    

@app.route('/api/swap_status', methods=['POST'])
def status():
    from app.models import Tecnico  # db é necessário para commit
    data = request.get_json()

    _id = int(data.get('id'))
    novo_status = data.get('status')

    if not _id or not novo_status:
        return {'error': 'ID e status são obrigatórios.'}, 400
        

    tecnico = Tecnico.query.filter_by(id=_id).first()

    if not tecnico:
        return {'error': 'Técnico não encontrado.'}, 404

    tecnico.status = novo_status
    db.session.commit()

    return {'message': 'Status atualizado com sucesso.'}, 200



@app.route('/api/tecnico/upload_foto', methods=['POST'])
def upload_foto():
    from app.models import Tecnico

    id = request.form.get('id')
    imagem = request.files.get('imagem')

    if not id or not imagem:
        return jsonify({'erro': 'Id e imagem são obrigatórios'}), 400

    if not extensao_permitida(imagem.filename):
        return jsonify({'erro': 'Extensão não permitida'}), 400

    tecnico = Tecnico.query.filter_by(id=id).first()
    if not tecnico:
        return jsonify({'erro': 'Técnico não encontrado'}), 404

    nome_arquivo = secure_filename(f"{tecnico.id}_{imagem.filename}")
    caminho = os.path.join(app.config['UPLOAD_FOLDER'], nome_arquivo)
    imagem.save(caminho)

    tecnico.imagem = nome_arquivo
    db.session.commit()

    return jsonify({'mensagem': 'Imagem atualizada com sucesso', 'imagem': nome_arquivo})
