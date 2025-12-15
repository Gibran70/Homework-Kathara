#!/bin/bash

# ==========================================
# Script di Test per la Rete FCI - Kathara
# ==========================================

# Definizione degli indirizzi IP delle sedi (Host)
# Dati presi da sedi.txt 
declare -A sedi
sedi=(
    ["veneto"]="10.42.0.2"
    ["calabria"]="10.42.32.2"
    ["puglia"]="10.42.64.2"
    ["sicilia"]="10.42.96.2"
    ["sardegna"]="10.42.112.2"
    ["marche"]="10.42.120.2"
    ["toscana"]="10.42.124.2"
    ["liguria"]="10.42.128.2"
    ["campania"]="10.42.130.2"
)

# Indirizzo di R1 (Gateway Internet) per testare l'uscita
# Preso da routers.txt (eth0 di R1) 
R1_TARGET="10.42.130.133"

echo "=============================================="
echo "AVVIO TEST DI CONNETTIVITÀ (Full Mesh + Internet)"
echo "=============================================="

errori=0
totale_test=0

# Ciclo esterno: Sede Sorgente
for src in "${!sedi[@]}"; do
    echo "----------------------------------------------"
    echo "Test da SEDE: $src"
    
    # 1. Test verso Internet (R1)
    echo -n "  -> Internet (R1): "
    kathara exec "$src" -- ping -c 1 -W 1 "$R1_TARGET" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "OK"
    else
        echo "FAIL !!!"
        ((errori++))
    fi
    ((totale_test++))

    # 2. Test verso tutte le altre sedi
    for dst in "${!sedi[@]}"; do
        # Non pingare se stesso
        if [ "$src" != "$dst" ]; then
            dst_ip=${sedi[$dst]}
            
            echo -n "  -> $dst ($dst_ip): "
            
            # Esecuzione del ping dentro il container
            # -c 1: un solo pacchetto
            # -W 1: timeout di 1 secondo (per non bloccare lo script se fallisce)
            kathara exec "$src" -- ping -c 1 -W 1 "$dst_ip" > /dev/null 2>&1
            
            if [ $? -eq 0 ]; then
                echo "OK"
            else
                echo "FAIL !!!"
                ((errori++))
            fi
            ((totale_test++))
        fi
    done
done

echo "=============================================="
echo "RISULTATO FINALE"
echo "=============================================="
if [ $errori -eq 0 ]; then
    echo "TUTTI I TEST PASSATI ($totale_test/$totale_test)"
    echo "La rete è perfettamente convergente."
else
    echo "CI SONO STATI $errori ERRORI SU $totale_test TEST."
    echo "Controlla le rotte dei nodi che hanno dato FAIL."
fi