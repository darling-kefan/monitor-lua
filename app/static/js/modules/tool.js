var Tool = {
    Error500lua : {
        generate : function(url) {
            var id  = $('input[name=id]');
            var codeArea = $('#lua_code');
            console.log(id.val());

            $.ajax({
                url: url,
                type: "GET",
                data: {'id': id.val()},
                dataType: "json",
                cache: false,
                success: function(response) {
                    console.log(response);
                    if(response.errcode == '0') {
                        codeArea.show();
                        codeArea.html(response.data);
                        $('#copy_code').show();
                        $('#download_code').show();
                    } else {
                        codeArea.html(response.errmsg);
                        $('#copy_code').hide();
                        $('#download_code').hide();
                    }
                }
            });
        },
        copy : function() {
            var btn = $('#copy_code');
            ZeroClipboard.config({forceEnhancedClipboard: true});
            var client = new ZeroClipboard(btn);

            client.on( 'ready', function(event) {
                client.on( 'copy', function(event) {
                    event.clipboardData.setData('text/plain', $('#lua_code').text());
                });

                client.on( 'aftercopy', function(event) {
                    $('#copy_code_status').show();
                });
            });
        },
        download : function(url) {
            location.href=url;
        }
    }
}