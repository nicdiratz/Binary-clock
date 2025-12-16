.org 0x00   # al complitore: metti prossimo codice a adr 0 per reset
rjmp start        ; reset vector

start:
    ldi r16, 0b00000111   ; 1011
    out DDRB, r16 ; PB0 come output
    rjump main

main:

    sbis PINA,7
    rcall pre_bottoni
    ldi r31, 0
    ldi r30, 0
    # start rtc
    rcall alza_SDA
    rcall alza_SCL

    ; 2. Genera START: SDA cade da HIGH a LOW mentre SCL HIGH

    
    rcall abbassa_SDA  
    nop
    rcall abbassa_SCL
    nop
    
    ldi r16, 0xD0 
    ldi r17, 8
    rcall invia_by_rtc
    nop
    ldi r16, 0x00
    ldi r17, 8
    rcall invia_by_rtc

    sbis PINA,7
    rcall pre_bottoni

    rcall leggi_by_rtc

    ; r17 r18 r19
    rcall crea_secondi
    nop
    rcall datashifto

; LOW  =  DDR 1 + PORT 0

; High =  DDR 0 + PORT 1


invia_by_rtc:
; SCL è già low 

    sbrc r16, 7
    rcall alza_SDA
    sbrs r16, 7
    rcall abbassa_SDA
    
    rcall alza_SCL
    rcall abbassa_SCL
    ; Clock pulse

    lsl r16
    dec r17
    brne invia_by_rtc

    ;ACK
    cbi DDRA,0          ; SDA input
    rcall alza_SCL

    ; Leggi ACK
    sbic PINA,0         ; se HIGH → NACK
    clc                 ; ack OK = C=0
    sbis PINA,0
    sec                 ; nack = C=1

    rcall abbassa_SCL

    sbi DDRA,0          ; SDA torna output
    ret




leggi_by_rtc:
    ldi r21, 0          ; contatore bit

    ldi r20, 8
    sec_loop:
        cp r21, r20
        brge min_read

        rcall i2c_read_bit
        lsl r17
        sbic PINA,0
        ori r17,1

        inc r21
        rjmp sec_loop

    min_read:
        ; manda ACK al byte secondi
        rcall i2c_send_ack

        ldi r20,16
    min_loop:
        cp r21, r20
        brge hour_read

        rcall i2c_read_bit
        lsl r18
        sbic PINA,0
            ori r18,1

        inc r21
        rjmp min_loop

    hour_read:
        ; ACK ai minuti
        rcall i2c_send_ack

        ldi r20,24
    hour_loop:
        cp r21, r20
        brge end_read

        rcall i2c_read_bit
        lsl r19
        sbic PINA,0
            ori r19,1

        inc r21
        rjmp hour_loop

    end_read:
        ; NACK al terzo byte
        rcall i2c_send_nack

        mov r20, r19
        subi r29,12
        brmi sta_bene
        mov r19, r20
        sta bene:
            nop
        lsl r19
        lsl r19
        lsl r19
        lsl r19

        lsl r18
        lsl r18
        ret
;   r17 secondi
;   r18 minuti
;   r19 ore
crea_secondi:
    mov r22, r17 ;voglio copiare il registro 18
                ; mi servono 4 bit e 4 bit da convertire 
    andi r22, 0x0F
    andi r17, 0xF0     ; high
    lsl r17
    lsl r17
    lsl r17
    lsl r17
    
    mov r21, r17
    rcall loopex
    mov r17, r21 
    mov r21, r22
    rcall loopex
    mov r22, r21
    ; così: r17 ha lsb...msb high
    ; e :   r22 ha lsb...msb low
    ret


pre_bottoni:
    ldi r24, 0
    ldi r20, 0          ; contatore = 0

pre_loop:
    sbis PINA,7         ; bottone rilasciato?
    rjmp pre_done       ; se sì, esci

    rcall aspe          ; breve delay
    inc r20
    cpi r20, 16         ; se raggiunti ~4 secondi (dipende da aspe)
    brlo pre_loop       ; ripeti finché contatore < soglia

pre_done:
    rjmp bottoni        ; timeout raggiunto → entra in modalità bottoni


bottoni:
    ; MANDO 00 A DATASHIFTER secondi 


    ; se bottone ore premuto cambio ore
    ; se bottone minuti premuto cambio minuti
    ; finito il chekc se sono premuti e se si cambio 
    ;controlli se il bottone è premuto
    ;Se sì → resetta il contatore a 0
    ;Se no → incrementa contatore
    ;Quando contatore = 200 → esci

    ldi r17, 0b10100101
    ldi r20, 0b01001000
    
    add r18, r30
    add r19, r31
    
    
    ldi r16, 4
    mov r21, r19
    rcall send_loop
    ldi r16, 6
    mov r21, r18
    rcall send_loop
    ldi r16, 14
    mov r21, r17
    rcall send_loop
    mov r21, r22
    rcall send_loop

    ; latch
    sbi PORTB, 3
    cbi PORTB, 3

    sbis PINA,7
    rcall hour
    
    sbis PINA,6
    rcall minut

    inc r24
    ; fai finire in caso di 400
    cpi r24, 400 
    breq exo
    rjump bottoni
    exo:
        ret
    hour:
        ldi r24, 0
        ldi r20, 0
    hour_loop:    
        add r19, r31
        ldi r16, 4
        mov r21, r19
        rcall send_loop
        ldi r16, 6
        ldi r21, 0
        rcall send_loop
        ldi r16, 14
        mov r21, r19
        rcall loopex 
        lsl r21
        rcall send_loop     ; usa già 21 per storing
        ldi r21, 0
        rcall send_loop
        sbi PORTB, 3        ; latch
        cbi PORTB, 3


        sbis PINA, 7
        rjump add_ora

        inc r20
        cpi r20, 200        ; ≈ 5 secondi
        brlo hour_loop
        ret                 ; timeout → esci

        breq bottoni
        rjump hour

        add_ora:
            inc r31             ; aggiungi 1 ora
            ldi r20, 0 
        wait_release:           ; serve così un click anche lungo incrementa solo di uno
            sbis PINA,7
            rjmp wait_release

            rjmp hour_loop
        wait_torna: 

    minut:
        ldi r24, 0
        ldi r20, 0
    minut_loop:    
        add r18, r30
        ldi r16, 4
        ldi r21, 0
        rcall send_loop
        ldi r16, 6
        mov r21, r18
        rcall send_loop
        ldi r16, 14
        mov r17,r18
        lsr r17
        lsr r17
        ldi r22, 0
        rcall loop_div10    ;converto

        mov r21, r17
        rcall loopex 
        lsl r21
        rcall send_loop     ; usa già 21 per storing
        ldi r21, r22
        rcall loopex
        lsl r21 
        rcall send_loop
        sbi PORTB, 3        ; latch
        cbi PORTB, 3


        sbis PINA, 7
        rjump add_min

        inc r20
        cpi r20, 200        ; ≈ 5 secondi
        brlo minut_loop
        ret                 ; timeout → esci

        breq bottoni
        rjump minut

        add_min:
            inc r31             ; aggiungi 1 ora
            ldi r20, 0 
        wait_release1:           ; serve così un click anche lungo incrementa solo di uno
            sbis PINA,7
            rjmp wait_release1

            rjmp minut_loop

loop_div10:
    cpi r17,10
    brlo done_div10
    subi r17, 10
    inc r22
    rjmp loop_div10

done_div10:
    ret

loopex:
    cpi r21, 0
    breq if0
    cpi r21,1
    breq if1
    cpi r21,2
    breq if2
    cpi r21,3
    breq if3
    cpi r21,4
    breq if4
    cpi r21,5
    breq if5
    cpi r21,6
    breq if6
    cpi r21,7
    breq if7
    cpi r21,8
    breq if8
    cpi r21,9
    breq if9
    cpi r21,10
    breq ifA
    cpi r21,11
    breq ifB
    cpi r21,12
    breq ifC
    cpi r21,13
    breq ifD
    cpi r21,14
    breq ifE
    cpi r21,15
    breq ifF
    

    if0:
        ldi r21, 0b00111111
        ret
    if1:
        ldi r21, 0b00001001
        ret
    if2:
        ldi r21, 0b01011110
        ret
    if3:
        ldi r21, 0b01011011
        ret
    if4:
        ldi r21, 0b01101001
        ret
    if5:
        ldi r21, 0b01110011
        ret
    if6:
        ldi r21, 0b01110111
        ret
    if7:
        ldi r21, 0b00011001
        ret
    if8:
        ldi r21, 0b01111111
        ret
    if9:
        ldi r21, 0b01111011
        ret
    ifA:
        ldi r21, 0b01111101
        ret
    ifB:
        ldi r21, 0b01100111
        ret
    ifC:
        ldi r21, 0b00110110
        ret
    ifD:
        ldi r21, 0b01001111
        ret
    ifE:
        ldi r21, 0b01110110
        ret
    ifF:
        ldi r21, 0b01011001
        ret


; CLK PB3
; LATCH PB1
; DATA PB0

; per ogni bit mando clock poi alla fine latch
; alla fine di 10 bit però devo convertirli in hex per lui  
; r16 contiene il byte da inviare
; PORTB bit0 = DS, bit1 = SH_CP, bit2 = ST_CP
datashifto:
    add r18, r30
    add r19, r31
    lsl r17
    sbrc r22,0
    sbi r17,0   ; in questo modo ho messo il primo bit di r22
    lsl r22     ; l'ho dato a r17 e poi slido r22
    lsl r22


    ldi r16, 4
    mov r21, r19
    rcall send_loop
    ldi r16, 6
    mov r21, r18
    rcall send_loop
    ldi r16, 14
    mov r21, r17
    rcall send_loop
    mov r21, r22
    rcall send_loop

    ; latch
    sbi PORTB, 3
    cbi PORTB, 3




send_loop:
    sbrc r21, 7  ; salta se bit7 = 0
    sbi PORTB, 0 ; DS = 1
    sbrs r21, 7  ; salta se bit7 = 1
    cbi PORTB, 0 ; DS = 0

    sbi PORTB, 1 ; SH_CP pulse
    cbi PORTB, 1

    lsl r21       ; shift left prossimo bit
    dec r16
    brne send_loop
    ret










asp:
    ldi r21, 50
    outer_loop:
        ldi r22, 200
    inner_loop:
        dec r22
        brne inner_loop
        dec r21
        brne outer_loop
    ret


aspe:
    ldi  r22, 250      ; loop esterno
    outer_loop:
        ldi  r21, 200  ; loop medio
    middle_loop:
            ldi  r20, 8    ; loop interno
    inner_loop:
            dec r20
            brne inner_loop
            dec r21
            brne middle_loop
        dec r22
        brne outer_loop  
    
;aspetto 4 secondi, se continua ad essere premuto entro in modalità 
;ogni volta che ho cliccato qualcosa entro in modalità dove ricomincio
; dopodichè se non è stato ripremuto torno normale





i2c_read_bit:
    rcall abbassa_SCL
    cbi DDRA,0          ; SDA input
    rcall alza_SCL
    ret
i2c_send_ack:
    rcall abbassa_SCL
    rcall abbassa_SDA   ; SDA LOW → ACK
    rcall alza_SCL
    rcall abbassa_SCL
    ret
i2c_send_nack:
    rcall abbassa_SCL
    rcall alza_SDA      ; SDA HIGH → NACK
    rcall alza_SCL
    rcall abbassa_SCL
    ret

alza_SDA:
    rcall delay
    cbi DDRA, 0
    sbi PORTA, 0
abbassa_SDA:
    rcall delay
    sbi DDRA, 0
    cbi PORTA, 0
alza_SCL:
    rcall delay
    cbi DDRA, 1
    sbi PORTA, 1
abbassa_SCL:
    rcall delay
    sbi DDRA, 1
    cbi PORTA, 1



delay:
    nop
    nop
    nop
    ret


    

