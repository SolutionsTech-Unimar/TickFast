document.getElementById('form-cadastro').addEventListener('submit', async function(event) {
    event.preventDefault(); // Evita o reload padrão do form

    // Captura os valores dos campos
    const nome = document.getElementById('nome').value;
    const nomeRegex = /^[a-zA-ZáéíóúãõâêîôûçÁÉÍÓÚÂÊÎÔÛÇ\s]+$/;
     if (!nomeRegex.test(nome)) {
        alert("O nome completo deve conter apenas letras e espaços.");
    }
    const email = document.getElementById('email').value;
    const senha = document.getElementById('senha').value;
    const especialidade = document.getElementById('especialidade').value;
    const horaEntrada = document.getElementById('horaEntrada').value;
    const horaSaida = document.getElementById('horaSaida').value;

    // Monta o objeto JSON
    const tecnico = {
        nome: nome,
        email: email,
        senha: senha,
        especialidade: especialidade,
        horaEntrada: horaEntrada,
        horaSaida: horaSaida
    };

    try {
        const response = await fetch('/cadastro', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(tecnico)
        });

        const result = await response.json();
         if (response.status == 200) {
            Swal.fire({
                title: "Cadastrado com sucesso! Esta conta tem acesso ao app mobile!",
                width: 600,
                padding: "3em",
                color: "rgb(119, 15, 250)",
                background: "#fff url('../static/images/swalala.jpg')"
            }).then(() => {
                window.location.href = "/tick_fast";  // Redireciona para a rota principal
            });
        }
        else {
            Swal.fire({
                icon: "error",
                title: "Oops...",
                text: "Algo deu errado no cadastro!",
            });
        }
    } catch (error) {
        console.error("Erro na requisição:", error);
        alert("Erro de conexão com o servidor.");
    }
});