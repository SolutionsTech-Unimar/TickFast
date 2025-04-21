document.addEventListener("DOMContentLoaded", function () {
    const btnPessoa = document.getElementById("btnPessoa");
    const btnCarta = document.getElementById("btnCarta");
    const sidebarPessoa = document.getElementById("sidebarPessoa");
    const sidebarCarta = document.getElementById("sidebarCarta");

    function toggleSidebar(sidebar) {
        if (sidebar.classList.contains("active")) {
            sidebar.classList.remove("active");
        } else {
            sidebarPessoa.classList.remove("active");
            sidebarCarta.classList.remove("active");
            sidebar.classList.add("active");
        }
    }

    btnPessoa.addEventListener("click", function () {
        toggleSidebar(sidebarPessoa);
    });

    btnCarta.addEventListener("click", function () {
        toggleSidebar(sidebarCarta);
    });


    document.querySelectorAll(".close-btn").forEach(button => {
        button.addEventListener("click", function () {
            this.parentElement.classList.remove("active");
        });
    });

    //---------------------------------------------------------------------

    var map = L.map('map').setView([-22.2369871525773, -49.96606033305354], 15); // Use um zoom menor (22 é exagerado)

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(map);
    
    let ceps = [];
    let dataSelecionada = new Date()

    async function listTickets(sidebarId) {
        const sidebar = document.getElementById(sidebarId);

        try {

            const res = await fetch("http://localhost:5000/tickets", {
                method: "GET",
                headers: {
                    "content-type": "application/json"
                }
            });

            if (!res.ok) {
                console.error("Erro ao buscar tickets:", res.status);
                return;
            }

            const tickets = await res.json();
            ceps = tickets.map(ticket => ticket.cep);

            sidebar.querySelectorAll('.ticket-box').forEach(el => el.remove());

            tickets.forEach(ticket => {
                if (datasIguais(new Date(ticket.data), dataSelecionada)) {
                    const ticketDiv = document.createElement('div');
                    ticketDiv.className = 'ticket-box';
                    ticketDiv.innerHTML = `
                    <h3>${ticket.produto}</h3>
                    <p><strong>Nome:</strong> ${ticket.nome}</p>
                    <p><strong>CEP:</strong> ${ticket.cep}</p>
                    <p><strong>Status:</strong> ${ticket.status} </p>
                `;
                    sidebar.appendChild(ticketDiv);
                }
            });

        } catch (error) {
            console.error("Erro ao carregar tickets:", error);
        }
    }

    let marcadoresPorCep = {};

    async function plotarCepNoMapa() {
        for (const cep of ceps) {
          const viaCepResponse = await fetch(`https://viacep.com.br/ws/${cep}/json/`);
          const viaCepData = await viaCepResponse.json();
    
          const endereco = `${viaCepData.logradouro}, ${viaCepData.localidade}, ${viaCepData.uf}`;
    
          // Nominatim para pegar latitude e longitude
          const nominatimResponse = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(endereco)}`);
          const nominatimData = await nominatimResponse.json();
    
          if (marcadoresPorCep[cep]) return;

          if (nominatimData.length > 0) {
            const { lat, lon } = nominatimData[0];
    
            // Debug para ver as coordenadas no console
            
            const marcador = L.marker([lat, lon]).addTo(map);
            marcadoresPorCep[cep] = marcador;
            console.log(`CEP: ${cep} -> Latitude: ${lat}, Longitude: ${lon}`);
            
          } 
          else {
            console.warn(`CEP: ${cep} não encontrou latitude e longitude.`);
          }
        }
    }



    setInterval(() => listTickets('sidebarCarta'), 5000);
    setInterval(plotarCepNoMapa, 5000);


    window.onload = () => {
        listTickets('sidebarCarta');
        plotarCepNoMapa();
        console.log("Página carregada e métodos executados!");
    };
   
    //---------------------------------------------------------------------

    updateDataMapa(dataSelecionada)

    //---------------------------------------------------------------------
      
    const calendarButton = document.querySelector('.header-button-calendario');
    const mapButton = document.querySelector('.header-button-mapa');
    const calendarDiv = document.getElementById('calendar');
    const mapDiv = document.getElementById('map');

    const calendar = new FullCalendar.Calendar(calendarDiv, {
        initialView: 'dayGridMonth',
        locale: 'pt-br',
        buttonText: {
            today: 'Hoje',
        },
        dateClick: function (info) {
            dataSelecionada = info.date
            listTickets('sidebarCarta')
            updateDataMapa(dataSelecionada)
            mapButton.click()
        },
        contentHeight: 670
    });
    calendar.render();
    calendarDiv.style.display = 'none';

    calendarButton.addEventListener('click', () => {
        calendarDiv.style.display = 'block';
        mapDiv.style.display = 'none';
    });

    mapButton.addEventListener('click', () => {
        calendarDiv.style.display = 'none';
        mapDiv.style.display = 'block';
    });

});

function updateDataMapa(data) {
    dayjs.locale('pt-br');

    const spanDiaAtual = document.getElementById("dia-atual");
    spanDiaAtual.textContent = dayjs(data).format('dddd D,').replace(/(^|\s|-)([a-zà-ú])/gi, (match, separador, letra) => {
        return separador + letra.toUpperCase();
    })

    const spanMesAtual = document.getElementById("mes-atual");
    spanMesAtual.textContent = dayjs(data).format('MMMM YYYY').replace(/(^|\s|-)([a-zà-ú])/gi, (match, separador, letra) => {
        return separador + letra.toUpperCase();
    })
}

function datasIguais(d1, d2) {
    return (
      d1.getDate() === d2.getDate() &&
      d1.getMonth() === d2.getMonth() &&
      d1.getFullYear() === d2.getFullYear()
    );
}