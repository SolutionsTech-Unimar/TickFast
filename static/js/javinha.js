//----------------Eventos no DOM -----------//

document.addEventListener("DOMContentLoaded", function () {
    const btnPessoa = document.getElementById("btnPessoa");
    const btnCarta = document.getElementById("btnCarta");
    const sidebarTecnico = document.getElementById("sidebarTecnico");
    const sidebarCarta = document.getElementById("sidebarCarta");

    function toggleSidebar(sidebar) {
        if (sidebar.classList.contains("active")) {
            sidebar.classList.remove("active");
        } else {
            sidebarTecnico.classList.remove("active");
            sidebarCarta.classList.remove("active");
            sidebar.classList.add("active");
        }
    }

    btnPessoa.addEventListener("click", function () {
        toggleSidebar(sidebarTecnico);
    });

    btnCarta.addEventListener("click", function () {
        toggleSidebar(sidebarCarta);
    });

    btnHelp.addEventListener("click", function () {
        Swal.fire({
            title: "Suporte",
            text: "Em caso de dúvidas, entre em contato com o nosso suporte: +55 14 99114-8278",
            icon: "question",
            backdrop: 'rgba(0, 0, 0, 0.84)'
        });
    });

    document.querySelectorAll(".close-btn").forEach(button => {
        button.addEventListener("click", function () {
            this.parentElement.classList.remove("active");
        });
    });

    //--------------------Adiciona Tickets--------------------//


     //-------DesignPingTick|

        var tickIcon = L.icon({
            iconUrl: '/static/images/Ticket.png',
            iconAnchor: [60, 70],
            iconSize: [30,30],
            className: 'ticket-icone'
        });
    //----------------------|

    async function listTickets(sidebarId) {
        const sidebar = document.getElementById(sidebarId);

        try {
            ceps = [];

            const res = await fetch("http://localhost:5000/tickets", {
                method: "GET",
                headers: {
                    "Content-Type": "application/json"
                }
            });

            if (!res.ok) {
                console.error("Erro ao buscar tickets:", res.status);
                return;
            }

            const tickets = await res.json();
            const ticketsDoDia = tickets.filter(ticket => {
                if (!ticket.data) return false;
                return datasIguais(new Date(ticket.data + "Z"), dataSelecionada);
            });

            ceps = ticketsDoDia.map(ticket => ticket.cep);

            sidebar.querySelectorAll('.ticket-box').forEach(el => el.remove());

            ticketsDoDia.forEach(ticket => {
                const ticketDiv = document.createElement('div');
                ticketDiv.className = 'ticket-box';
                ticketDiv.innerHTML = `
                <h3>${ticket.produto}</h3>
                <p><strong>ID:</strong> [${ticket.id}]</p>
                <p><strong>Nome:</strong> ${ticket.nome}</p>
                <p><strong>CEP:</strong> ${ticket.cep}</p>
                <p><strong>Status:</strong> ${ticket.status}</p>
            `;
                sidebar.appendChild(ticketDiv);
            });

        } catch (error) {
            console.error("Erro ao carregar tickets:", error);
        }

        for (const cep of ceps) {
            try {
                await plotarCepNoMapa(cep);
            } catch (e) {
                console.error("Erro ao plotar CEP no mapa:", cep, e);
            }
        }
    }
    //--------------------------------Adiciona Tecnicos-------------------------------//

    const capitalizarPrimeiraLetra = (texto) => {
        if (!texto) return "";
        return texto.charAt(0).toUpperCase() + texto.slice(1).toLowerCase();
    };

    async function listTecnicosComTickets(sidebarId) {
        const sidebar = document.getElementById(sidebarId);
        try {
            const res = await fetch("http://localhost:5000/tecnicos", {
                method: "GET",
                headers: {
                    "Content-Type": "application/json"
                }
            });

            if (!res.ok) {
                console.error("Erro ao buscar técnicos:", res.status);
                return;
            }

            const tecnicos = await res.json();
            sidebar.querySelectorAll('.tecnico-box').forEach(el => el.remove());

            // Separar técnicos ativos e inativos
            const ativos = tecnicos.filter(t => t.status.toLowerCase() === 'ativo');
            const outros = tecnicos.filter(t => t.status.toLowerCase() !== 'ativo');

            // Juntar com ativos primeiro
            const ordenados = [...ativos, ...outros];

            ordenados.forEach(tecnico => {
                const tecnicoDiv = document.createElement('div');
                tecnicoDiv.className = 'tecnico-box';
                tecnicoDiv.innerHTML = `
                <div class="tecnico-header">
                  <div class="foto-e-nome">
                    <div class="foto-perfil">
                         <img src="${tecnico.imagem}" alt="Foto de ${tecnico.nome}"/>
                    </div>
                    <div class="nome-status">
                      <div class="nome-tecnico">${tecnico.nome} #${tecnico.id}</div>
                      <div class="texto-status">${tecnico.status.toUpperCase()}</div>
                    </div>
                  </div>
                  <div class="status-indicador status-${tecnico.status.toLowerCase()}"></div>
                </div>
                <div class="tecnico-footer">
                    <div class="especialidade">Esp.: ${capitalizarPrimeiraLetra(tecnico.especialidade)}</div>
                    <div class="ticketsT">Tickets: ${tecnico.tickets_abertos}</div>
                </div>
            `;
                sidebar.appendChild(tecnicoDiv);
            });

        } catch (error) {
            console.error("Erro ao carregar técnicos:", error);
        }
    }

    //-------------------------------------------Leaflet-----------------------------------------//
    var map = L.map('map').setView([-22.2369871525773, -49.96606033305354], 15); // Use um zoom menor (22 é exagerado)

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(map);

    //--------------------------------Pingar tecnicos no mapa ------------------------------------//




    //-------DesignPing|
    const tecIconSize = [40, 40]; // Tamanho desejado

    const pingIcon = (urlImg) => L.icon({
        iconUrl: urlImg,
        iconSize: tecIconSize,
        iconAnchor: [25, 25], // centraliza
        className: 'foto-icone' // adiciona uma classe CSS para arredondar
    });
    //-----------------|

    const marcadores = {}; // Guarda marcadores no mapa por ID

    async function pingarTecnicos() {
        try {
            const res = await fetch("http://localhost:5000/api/tecnicos/ativos");
            const tecnicos = await res.json();

            tecnicos.forEach(t => {
                if (t.ativo) {
                    // Criar novo marcador ou atualizar posição
                    if (marcadores[t.id]) {
                        marcadores[t.id].setLatLng([t.latitude, t.longitude]);
                    } else {
                        const marker = L.marker([t.latitude, t.longitude], {
                            icon: pingIcon(t.imagem)  // <-- foto como ícone
                        })
                            .addTo(map)
                            .bindPopup(`Técnico ID: ${t.id}`);
                        marcadores[t.id] = marker;
                    }
                } else {
                    // Remover marcador se técnico ficou inativo
                    if (marcadores[t.id]) {
                        map.removeLayer(marcadores[t.id]);
                        delete marcadores[t.id];
                    }
                }
            });

        } catch (error) {
            console.error("Erro ao buscar técnicos ativos:", error);
        }
    }


    //--------------------------------Pingar tickets no mapa ------------------------------------//
    let ceps = [];
    let dataSelecionada = new Date()
    let marcadoresPorCep = {};

    async function plotarCepNoMapa(cep) {
        const viaCepResponse = await fetch(`https://viacep.com.br/ws/${cep}/json/`);
        const viaCepData = await viaCepResponse.json();

        const endereco = `${viaCepData.logradouro}, ${viaCepData.localidade}, ${viaCepData.uf}`;

        // Nominatim para pegar latitude e longitude
        const nominatimResponse = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(endereco)}`);
        const nominatimData = await nominatimResponse.json();

        if (marcadoresPorCep[cep] || !ceps.includes(cep)) return;

        if (nominatimData.length > 0) {
            const { lat, lon } = nominatimData[0];
            // Debug para ver as coordenadas no console

            const marcador = L.marker([lat, lon], {icon: tickIcon}).addTo(map);
            marcadoresPorCep[cep] = marcador;
            console.log(`CEP: ${cep} -> Latitude: ${lat}, Longitude: ${lon}`);

        }
        else {
            console.warn(`CEP: ${cep} não encontrou latitude e longitude.`);
        }
    }

    setInterval(() => {
        listTickets('sidebarCarta');
        listTecnicosComTickets('sidebarTecnico');
        pingarTecnicos();
    }, 10000);


    window.onload = () => {
        listTecnicosComTickets('sidebarTecnico')
        listTickets('sidebarCarta');
        pingarTecnicos()
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
            for (const cep in marcadoresPorCep) {
                map.removeLayer(marcadoresPorCep[cep]);
            }
            marcadoresPorCep = {}
            listTickets('sidebarCarta')
            updateDataMapa(dataSelecionada)
            mapButton.click()
        },
        contentHeight: 670,
        eventsSet: function (events) {
            document.querySelectorAll('.event-pin').forEach(pin => pin.remove());

            events.forEach(event => {
                const dateStr = event.startStr.split('T')[0];
                const cell = document.querySelector(`[data-date="${dateStr}"]`);

                if (cell && !cell.querySelector('.event-pin')) {
                    const pin = document.createElement('span');
                    pin.className = 'event-pin';
                    cell.querySelector('.fc-daygrid-day-top')?.appendChild(pin);
                }
            });
        }
    });

    calendarDiv.style.display = 'none';

    calendarButton.addEventListener('click', () => {
        calendarDiv.style.display = 'block';
        mapDiv.style.display = 'none';
        calendar.render();
        carregarEventosNoCalendario();
    });

    mapButton.addEventListener('click', () => {
        calendarDiv.style.display = 'none';
        mapDiv.style.display = 'block';
    });

    async function carregarEventosNoCalendario() {
        try {
            const response = await fetch("http://localhost:5000/tickets");
            const tickets = await response.json();

            const eventos = tickets.map(ticket => ({
                title: ticket.produto,
                start: new Date(ticket.data + "Z"),
                allDay: true
            }));

            calendar.removeAllEvents();
            calendar.addEventSource(eventos);
        } catch (error) {
            console.error("Erro ao carregar tickets:", error);
        }
    }

    carregarEventosNoCalendario();

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

