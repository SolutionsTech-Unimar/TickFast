from flask import request, jsonify, render_template
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
    return render_template("EmployReg.html")

@app.route('/tick_fast')
def ticketapp():
    return render_template("TickFast.html")

@app.route('/contato', methods=['POST'])
def adicionar_ticket():
    try:
        from app.models import Ticket
        
        data = request.get_json()

       
        novo_ticket = Ticket(
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
            "data": ticket.data
        }
        for ticket in tickets
    ]
    return jsonify(tickets_list)
