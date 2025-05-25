from run import app, db

def distribuir_ticket(ticket):
    from app.models import Tecnico

    with open("debug.txt", "w+") as r:
        r.write("tnc")
    # Buscar técnicos com a especialidade do produto
    tecnicos_compativeis = Tecnico.query \
        .filter(Tecnico.especialidade == ticket.produto) \
        .all()

    tecnicos_disponiveis = [
        t for t in tecnicos_compativeis if len(t.tickets) < 5
    ]

    if not tecnicos_disponiveis:
        # Buscar técnicos "geral"
        tecnicos_gerais = Tecnico.query \
            .filter(Tecnico.especialidade == "geral") \
            .all()
       
        tecnicos_gerais_disponiveis = [
            t for t in tecnicos_gerais if len(t.tickets) < 5
        ]

        if tecnicos_gerais_disponiveis:
            tecnicos_disponiveis = tecnicos_gerais_disponiveis
        else:
            # Fallback: qualquer técnico com menos de 5 tickets
            tecnicos_outros = Tecnico.query.all()
            tecnicos_disponiveis = [
                t for t in tecnicos_outros if len(t.tickets) < 5
            ]

            if not tecnicos_disponiveis:
                return {"status": "pendente", "message": "Nenhum técnico disponível no momento."}

    # Ordenar por menos tickets e maior ID
    tecnicos_disponiveis.sort(key=lambda t: (len(t.tickets), -t.id))

    tecnico_escolhido = tecnicos_disponiveis[0]
    ticket.tecnico = tecnico_escolhido
    db.session.commit()

    return {
        "status": "atribuído",
        "tecnico_id": tecnico_escolhido.id,
        "tecnico_nome": tecnico_escolhido.nome
    }


UPLOAD_FOLDER = 'static/fotos_perfil'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

def extensao_permitida(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS