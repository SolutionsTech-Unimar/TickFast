document.getElementById('telefone').addEventListener('input', function (e) {
    var input = e.target;
    var value = input.value.replace(/\D/g, '');
    if (value.length <= 5) {
        input.value = '(' + value.substring(0, 2) + ') ' + value.substring(2);
    } else if (value.length <= 10) {
        input.value = '(' + value.substring(0, 2) + ') ' + value.substring(2, 6) + '-' + value.substring(6);
    } else {
        input.value = '(' + value.substring(0, 2) + ') ' + value.substring(2, 7) + '-' + value.substring(7, 11);
    }
});

document.getElementById('cep').addEventListener('input', function (e) {
    var input = e.target;
    var value = input.value.replace(/\D/g, '');

    if (value.length <= 5) {
        input.value = value.substring(0, 5);
    }
    if (value.length > 5) {
        input.value = value.substring(0, 5) + '-' + value.substring(5, 8);
    }
});

async function validarFormulario(event) {
    event.preventDefault();
    let errors = [];

    const nome = document.getElementById("nome").value;
    const nomeRegex = /^[a-zA-ZáéíóúãõâêîôûçÁÉÍÓÚÂÊÎÔÛÇ\s]+$/;
    if (!nomeRegex.test(nome)) {
        errors.push("O nome completo deve conter apenas letras e espaços.");
    }

    const cep = document.getElementById("cep").value;
    const cepRegex = /^\d{5}-\d{3}$/;
    if (!cepRegex.test(cep)) {
        errors.push("O CEP deve ser completamente preenchido.");
    }
    else if (!(await cepValido(cep))) {
        errors.push("O CEP não é válido");
    }

    const telefone = document.getElementById("telefone").value;
    const telefoneRegex = /^\(\d{2}\)\s\d{4,5}-\d{4}$/;
    if (!telefoneRegex.test(telefone)) {
        errors.push("O telefone deve ser completamente preenchido");
    }

    if (telefone === '(  ) ____-____' || telefone.trim() === '') {
        errors.push("O telefone deve ser completamente preenchido.");
    }

    const produto = document.getElementById("produto").value;
    if (produto == "") {
        errors.push("Você deve selecionar uma opção.");
    }

    if (errors.length > 0) {
        const errorMessagesContainer = document.getElementById("errorMessages");
        errorMessagesContainer.style.display = "block";
        errorMessagesContainer.innerHTML = errors.join("<br>");
    }
    else {
        const res = await fetch("http://localhost:5000/contato", {
            method: "POST",
            headers: {
                "content-type": "application/json"
            },
            body: JSON.stringify({
                nome: document.getElementById("nome").value,
                cep: document.getElementById("cep").value,
                telefone: document.getElementById("telefone").value,
                email: document.getElementById("email").value,
                produto: document.getElementById("produto").value,
                descricao: document.getElementById("descricao").value,
            })
        })

        if (res.status == 201) {
            Swal.fire({
                title: "Enviado com sucesso! Você receberá atualizações pelo email",
                width: 600,
                padding: "3em",
                color: "#716add",
                background: "#fff url('../static/images/trees.png')",
                backdrop: `
                  rgba(0,0,123,0.4)
                  url("../static/images/nyan-cat.gif")
                  left top
                  no-repeat
                `
            }).then(() => {
                window.location.href = "/";  // Redireciona para a rota principal
            });
        }
        else if (res.status == 200) {
            Swal.fire({
                icon: "success",
                title: "Ticket removido!",
            });
        }
        else if (res.status == 404) {
            Swal.fire({
                icon: "error",
                title: "Ticket não encontrado!",
            });
        }
        else {
            Swal.fire({
                icon: "error",
                title: "Oops...",
                text: "Algo deu errado!",
            });
        }
    }
}

async function cepValido(cep) {
    const res = await fetch(`https://viacep.com.br/ws/${cep}/json/`)
    const data = await res.json()
    if (data.erro) {
        return false;
    }
    return true;
}
