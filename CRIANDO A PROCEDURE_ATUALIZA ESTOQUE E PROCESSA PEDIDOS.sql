DELIMITER //

CREATE PROCEDURE processar_pedido(IN id_cliente INT, IN id_pagamento INT)
BEGIN
    -- Variáveis locais
    DECLARE quantidade_disponivel INT;
    DECLARE id_produto INT;
    DECLARE quantidade INT;
    DECLARE done INT DEFAULT 0;

    -- Cursor para selecionar os produtos do pedido
    DECLARE cursor_produtos CURSOR FOR
        SELECT id_produto, quantidade FROM itens_pedido WHERE id_cliente = id_cliente;

    -- Manipulador para encerrar o cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Abre o cursor
    OPEN cursor_produtos;

    -- Loop sobre os produtos do pedido
    produto_loop: LOOP
        FETCH cursor_produtos INTO id_produto, quantidade;
        IF done = 1 THEN
            LEAVE produto_loop;
        END IF;

        -- Verifica o estoque disponível
        SELECT quantidade_estoque INTO quantidade_disponivel FROM produtos WHERE id_produto = id_produto;

        -- Se o estoque for insuficiente, lança um erro
        IF quantidade_disponivel < quantidade THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estoque insuficiente para o produto';
        END IF;

        -- Atualiza o estoque, subtraindo a quantidade vendida
        UPDATE produtos
        SET quantidade_estoque = quantidade_estoque - quantidade
        WHERE id_produto = id_produto;
    END LOOP;

    -- Fecha o cursor
    CLOSE cursor_produtos;

    -- Atualiza o status do pedido e associa o pagamento
    UPDATE pedidos
    SET status_pedido = 'Concluído', id_pagamento = id_pagamento
    WHERE id_cliente = id_cliente;

END //

DELIMITER ;
