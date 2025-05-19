const contrato = document.getElementById("contrato");
const entrada = document.getElementById("horaEntrada");
const saida = document.getElementById("horaSaida");

contrato.addEventListener("input", () => {
    // Limpa o conteúdo anterior
    const mensagem = document.getElementById("msg")
    entrada.value = ""
    saida.value = ""

    if (contrato.value.toLowerCase() === "clt") {
        // Cria a div de alerta
        mensagem.innerText = "CLT dispõe de 8h na jornada de trabalho."
    }
    else{
        mensagem.innerText = "";
    }
});

// Sempre que a hora de entrada mudar, calcula a saída (+8h)
entrada.addEventListener("input", () => {
  if (!entrada.value) return;

  if(contrato.value.toLowerCase() === "clt") {
    const [horas, minutos] = entrada.value.split(":").map(Number);
    const novaHora = new Date();
    novaHora.setHours(horas + 8);
    novaHora.setMinutes(minutos);

    saida.value = novaHora.toTimeString().slice(0, 5); // Formata como HH:MM
  }
});

// Sempre que a hora de saída mudar, calcula a entrada (-8h)
saida.addEventListener("input", () => {
  if (!saida.value) return;

  if (contrato.value.toLowerCase() === "clt") {
    const [horas, minutos] = saida.value.split(":").map(Number);
    const novaHora = new Date();
    novaHora.setHours(horas - 8);
    novaHora.setMinutes(minutos);

    entrada.value = novaHora.toTimeString().slice(0, 5);
  }
});

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
    const contrato = document.getElementById('contrato').value;
    const especialidade = document.getElementById('especialidade').value;
    const horaEntrada = document.getElementById('horaEntrada').value;
    const horaSaida = document.getElementById('horaSaida').value;

    // Monta o objeto JSON
    const tecnico = {
        nome: nome,
        email: email,
        senha: senha,
        contrato: contrato,
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