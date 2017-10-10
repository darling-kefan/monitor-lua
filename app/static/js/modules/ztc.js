var Ztc = {
    Adserving : {
        District : {
            maxLevel : 3,
            fill : function (parentId, level) {
                if(level >= this.maxLevel) {
                    return;
                }

                for(var i = 0; i < this.maxLevel;  i++) {
                    if(i >= level) {
                        $('select[name="district'+ (i + 1) + '"] option:gt(0)').remove();
                    }
                }

                var element = $('select[name="district'+ (level + 1) + '"]');

                // 中国
                var did = 100000;
                if (level > 0) {
                    for(var i = districts.length - 1; i >= 0; i--) {
                        var district = districts[i];
                        if (district.districtId == parentId) {
                            did = district.did;
                        }
                    }
                }

                for(var i = districts.length - 1; i >= 0; i--) {
                    var district = districts[i];
                    if (district.level == level+1 && district.pid == did) {
                        $('<option value="'+ district.districtId +'">'+ district.name +'</option>').appendTo(element);
                    }
                }
            }
        }
    },

    Detail : {
        selectVersion : function (element) {
            $(element).parents('form').submit();
        }
    },

    Professional : {
        // 此方法一次性发出全部请求
        checkSyncAllPublishs : function (url) {
            $.each(publishs, function(key, publish){
                $.ajax({
                    url: url,
                    type: "GET",
                    data: {'publishId': publish.publishId, 'timePoint': publish.timePoint},
                    dataType: "json",
                    cache: false,
                    success: function(response) {
                        console.log(response);
                        if(response.errcode == '0') {
                            $('#isSync_' + publish.publishId + ' div').removeClass('loading-spinner');
                            $('#isSync_' + publish.publishId + ' div').addClass('glyphicon glyphicon-ok');
                        } else {
                            $('#isSync_' + publish.publishId + ' div').removeClass('loading-spinner');
                            $('#isSync_' + publish.publishId + ' div').addClass('glyphicon glyphicon-remove');
                        }
                    }
                });
            });
        },
        // 按计划id单个查看计划
        checkSyncPublish : function(publishId, timePoint, url) {
            $.ajax({
                url: url,
                type: "GET",
                data: {'publishId': publishId, 'timePoint': timePoint},
                dataType: "json",
                cache: false,
                success: function(response) {
                    console.log(response);
                    if(response.errcode == '0') {
                        $('#isSync_' + publishId + ' div').removeClass('loading-spinner');
                        $('#isSync_' + publishId + ' div').addClass('glyphicon glyphicon-ok');
                    } else {
                        $('#isSync_' + publishId + ' div').removeClass('loading-spinner');
                        $('#isSync_' + publishId + ' div').addClass('glyphicon glyphicon-remove');
                    }
                }
            });
        },
        // 显示/隐藏地区选择列表
        triggerDistrictSelect : function(element) {
            $targetTypeVal = $(element).val();
            if ($targetTypeVal == 1) {
                $('#districts_area').hide();
            } else {
                $('#districts_area').removeClass('hide');
                $('#districts_area').show();
            }
        }
    },

    Basic : {
        // 按计划id单个查看计划
        checkSyncPublish : function(publishId, key, url) {
            $.ajax({
                url: url,
                type: "GET",
                data: {'publishId': publishId, 'key': key},
                dataType: "json",
                cache: false,
                success: function(response) {
                    console.log(response);
                    if(response.errcode == '0') {
                        $('#isSync_' + publishId + ' div').removeClass('loading-spinner');
                        $('#isSync_' + publishId + ' div').addClass('glyphicon glyphicon-ok');
                    } else {
                        $('#isSync_' + publishId + ' div').removeClass('loading-spinner');
                        $('#isSync_' + publishId + ' div').addClass('glyphicon glyphicon-remove');
                    }
                }
            });
        }
    },

    SyncDetail : {
        checkSyncKey : function (nodeId, publishId, url) {
            key = nodeId.replace(/_/, ':');
            // console.log(key);
            console.log(nodeId);
            $.ajax({
                url: url,
                type: "GET",
                data: {'key': key, 'publishId': publishId},
                dataType: "json",
                cache: false,
                success: function(response) {
                    var content = response.data.content;
                    $.each(content, function (port, value) {
                        if (port == 6311) {
                            // console.log($('#' + nodeId).attr('class'));
                            $('#' + nodeId).removeClass('loading');
                            $('#' + nodeId).addClass('loaded');
                            $('#' + nodeId + '_cluster div').removeClass('loading-spinner');
                            if (value == null) {
                                $('#' + nodeId + '_cluster div').addClass('glyphicon glyphicon-remove');
                            } else {
                                $('#' + nodeId + '_cluster div').addClass('glyphicon glyphicon-ok');
                            }
                        } else {
                            // console.log($('#' + nodeId).attr('class'));
                            $('#' + nodeId).removeClass('loading');
                            $('#' + nodeId).addClass('loaded');
                            $('#' + nodeId + '_' + port + ' div').removeClass('loading-spinner');
                            if (value == null) {
                                $('#' + nodeId + '_' + port + ' div').addClass('glyphicon glyphicon-remove');
                            } else {
                                $('#' + nodeId + '_' + port + ' div').addClass('glyphicon glyphicon-ok');
                            }
                        }
                    });

                    return true;
                }
            });
        }
    }
};