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
     
    let renderedTicketIds = new Set();
    let ceps = [];

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


            tickets.forEach(ticket => {
                if (!renderedTicketIds.has(ticket.id)) {

                    renderedTicketIds.add(ticket.id);


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
            
          } else {
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
   
});
